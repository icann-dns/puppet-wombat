# @summary Wombat logger type
type Wombat::Logger = Struct[
  {
    level     => Enum['CRITICAL', 'ERROR', 'WARNING', 'INFO', 'DEBUG'],
    handlers  => String[1],
    qualname  => Optional[String[1]],
    propagate => Optional[Boolean],
  }
]
