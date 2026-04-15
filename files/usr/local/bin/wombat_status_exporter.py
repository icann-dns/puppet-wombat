#!/usr/bin/env python3
"""This is just a template of booiler plat code to copy into new scripts."""
import logging
import re
from argparse import ArgumentParser, Namespace
from pathlib import Path
from subprocess import PIPE, CalledProcessError, run

logger = logging.getLogger(__name__)

HEADER = '''
# HELP wombat_queue_incoming Number of incoming jobs
# TYPE wombat_queue_incoming gauge
# HELP wombat_queue_queued Number of queued jobs
# TYPE wombat_queue_queued gauge
# HELP wombat_queue_running Number of running jobs
# TYPE wombat_queue_running gauge
# HELP wombat_queue_workers Number of workers
# TYPE wombat_queue_workers gauge
# HELP wombat_queue_active Queue active state (1=active)
# TYPE wombat_queue_active gauge
# HELP wombat_import_active Global import state (1=active)
# TYPE wombat_import_active gauge
'''


def run_wombat_status():
    try:
        result = run(
            ["wombat-status"],
            stdout=PIPE,
            stderr=PIPE,
            text=True,
            check=True,
            timeout=10,
        )
        return result.stdout
    except CalledProcessError as e:
        print(f"# Error running wombat-status: {e}")
        raise SystemExit(1)


def get_args() -> Namespace:
    """Parse and return the arguments.

    Returns:
        Namespace: The parsed argument namespace
    """
    parser = ArgumentParser(description=__doc__)
    parser.add_argument('-v', '--verbose', action='count', default=0)
    parser.add_argument('output_file', help='Output file for metrics (textfile export folder)', type=Path)
    return parser.parse_args()


def get_log_level(args_level: int) -> int:
    """Convert an integer to a logging log level.

      Arguments:
          args_level (int): The log level as an integer

      Returns:
          int: the logging loglevel
    """
    return {
            0: logging.ERROR,
            1: logging.WARN,
            2: logging.INFO,
            3: logging.DEBUG,
            }.get(args_level, logging.DEBUG)


def parse_metrics(output:str ) -> list[str]:
    # sample output
    # ***********        Status of Gearman queues         **************
    #
    # ------------------------------------------------------------------
    # Wombat import:                                             ACTIVE
    # cdns         :    46 incoming
    # ------------------------------------------------------------------
    # import-tsv   :     0 queued,     0 running,   6 workers,   ACTIVE
    # cdns-to-pcap :     0 queued,     0 running,  16 workers,   ACTIVE
    # cdns-to-tsv  :     0 queued,     0 running,  16 workers,   ACTIVE
    metrics = []
    for line in output.splitlines():
        logger.debug(f"Parsing line: {line}")
        if line.startswith("Wombat import:"):
            status = line.split()[-1]
            active = 1 if status == "ACTIVE" else 0
            logger.debug(f"Parsed import status: {status} -> {active}")
            metrics.append(f'wombat_import_active {active}')
        elif line.startswith("cdns "):
            match = re.search(r'(\d+) incoming', line)
            if match:
                incoming = match.group(1)
                logger.debug(f"Parsed cdns incoming: {incoming}")
                metrics.append(f'wombat_queue_incoming{{queue="cdns"}} {incoming}')
        elif line.startswith(("import-tsv", "cdns-to-pcap", "cdns-to-tsv")):
            match = re.search(r'^([\w-]+)\s*:\s+(\d+)\s+queued,\s+(\d+)\s+running,\s+(\d+)\s+workers,\s+(\w+)', line)
            if match:
                queue, queued, running, workers, status_txt = match.groups()
                status = 1 if status_txt == "ACTIVE" else 0
                logger.debug(f"Parsed queue {queue}: queued={queued}, running={running}, workers={workers}, status={status_txt} -> {status}")
                metrics.append(f'wombat_queue_queued{{queue="{queue}"}} {queued}')
                metrics.append(f'wombat_queue_running{{queue="{queue}"}} {running}')
                metrics.append(f'wombat_queue_workers{{queue="{queue}"}} {workers}')
                metrics.append(f'wombat_queue_active{{queue="{queue}"}} {status}')
    return metrics


def main() -> int:
    """Main program Entry point.

    Returns:
        int: the status return code
    """
    args = get_args()
    logging.basicConfig(level=get_log_level(args.verbose))
    output = run_wombat_status()
    metrics = parse_metrics(output)
    args.output_file.write_text(HEADER + "\n".join(metrics) + "\n")
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
