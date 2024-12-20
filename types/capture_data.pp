# @summary Data types for capture data
type Wombat::Capture_data = Enum['query-questions', 'query-answers',
  'query-authority', 'query-additional', 'response-questions', 'response-answers',
  'response-authority', 'response-additional', 'query-all', 'response-all', 'all'
]
