# lex-temporal

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-temporal`
- **Version**: `0.1.0`
- **Namespace**: `Legion::Extensions::Temporal`

## Purpose

Provides temporal perception and time management for cognitive agents. Tracks elapsed time per domain and event pair, maintains deadlines with urgency scoring, models subjective time dilation based on arousal and cognitive load, and identifies temporal patterns (periodic, bursty, irregular, sparse) in event sequences. Allows the agent to ask "how long has it been since X?", "what's due soon?", and "when will Y happen next?"

## Gem Info

- **Gem name**: `lex-temporal`
- **License**: MIT
- **Ruby**: >= 3.4
- **No runtime dependencies** beyond the Legion framework

## File Structure

```
lib/legion/extensions/temporal/
  version.rb                     # VERSION = '0.1.0'
  helpers/
    constants.rb                 # urgency horizons, pattern types, limits, dilation range, alpha
    time_perception.rb           # TimePerception class — event timestamps, deadlines, subjective time
    temporal_pattern.rb          # TemporalPattern class — interval analysis and next-event prediction
    temporal_store.rb            # TemporalStore class — container for TimePerception + TemporalPattern instances
  runners/
    temporal.rb                  # Runners::Temporal module — all public runner methods
  client.rb                      # Client class including Runners::Temporal
```

## Key Constants

| Constant | Value | Purpose |
|---|---|---|
| `URGENCY_HORIZONS` | hash | `{ immediate: 300, soon: 3600, upcoming: 86400, distant: 604800 }` (seconds) |
| `URGENCY_LEVELS` | array | `:overdue`, `:immediate`, `:soon`, `:upcoming`, `:distant`, `:far_future` |
| `DEADLINE_URGENCY` | hash | Threshold fractions for mapping remaining/total time to urgency level |
| `PATTERN_TYPES` | 4 symbols | `:periodic`, `:bursty`, `:irregular`, `:sparse` |
| `MIN_PATTERN_OBSERVATIONS` | 5 | Minimum events before pattern classification |
| `MAX_EVENTS_PER_DOMAIN` | 100 | Maximum timestamped events per domain:event key |
| `MAX_DEADLINES` | 50 | Maximum tracked deadlines |
| `MAX_PATTERNS` | 30 | Maximum TemporalPattern instances |
| `PERIODIC_CV_THRESHOLD` | 0.3 | Coefficient of variation below this = periodic |
| `BURST_MULTIPLIER` | 0.25 | Fraction of mean interval; intervals below this = burst |
| `DILATION_RANGE` | 0.5–2.0 | Min/max subjective time dilation factor |
| `SUBJECTIVE_ALPHA` | 0.2 | EMA alpha for dilation updates |

## Helpers

### `Helpers::TimePerception`

Event timestamps, deadlines, and subjective time model.

- `initialize` — timestamps hash (keyed `"domain:event"`), deadlines hash, dilation=1.0
- `mark_event(domain:, event:)` — appends current Time to timestamps array; trims to MAX_EVENTS_PER_DOMAIN
- `elapsed_since(domain:, event:)` — seconds since last event of that type; nil if no record
- `time_since_first(domain:, event:)` — seconds since first recorded event of that type
- `event_count(domain:, event:)` — total recorded occurrences
- `set_deadline(id:, at:, description: '')` — stores deadline with created_at; returns nil if at MAX_DEADLINES
- `remove_deadline(id)` — deletes deadline record
- `deadline_urgency(id)` — `1.0 - (remaining_seconds / total_seconds).clamp(0, 1)`; overdue returns 1.0
- `overdue_deadlines` — deadlines where `at <= Time.now`
- `upcoming_deadlines(horizon: URGENCY_HORIZONS[:soon])` — deadlines within horizon seconds
- `update_subjective_time(arousal:, cognitive_load:)` — target_dilation = average of arousal and cognitive_load; EMA update: `dilation = dilation + SUBJECTIVE_ALPHA * (target - dilation)`, clamped to DILATION_RANGE
- `subjective_elapsed(domain:, event:)` — `elapsed_since * dilation`
- `overall_urgency` — mean urgency across all active deadlines; 0.0 if none

### `Helpers::TemporalPattern`

Interval analysis and next-event prediction for a domain:event key.

- `initialize(domain:, event:)` — observations array, intervals array, mean_interval=nil, pattern_type=:sparse
- `add_observation(timestamp)` — appends timestamp; if 2+ observations, computes interval from last; recomputes mean_interval and classifies pattern
- `classify_pattern` — `periodic` if CV < PERIODIC_CV_THRESHOLD; `bursty` if >30% intervals below BURST_MULTIPLIER * mean; `irregular` if 5+ observations and neither; `sparse` if < MIN_PATTERN_OBSERVATIONS
- `predict_next` — returns `{ predicted_at:, confidence: }` based on pattern_type; periodic: `last + mean_interval`, confidence 0.8; bursty: halved mean, confidence 0.5; irregular: mean, confidence 0.3; sparse: nil
- `record_actual(actual_time)` — checks accuracy within 30% tolerance of prediction; accuracy flag appended to history
- `periodic?` — pattern_type == :periodic
- `bursty?` — pattern_type == :bursty

## Runners

All runners are in `Runners::Temporal`. The `Client` includes this module and uses a `TemporalStore` instance (via `temporal_store` private method).

| Runner | Parameters | Returns |
|---|---|---|
| `mark_event` | `domain:, event:` | `{ success:, domain:, event:, count:, elapsed_since: }` |
| `elapsed_since` | `domain:, event:` | `{ success:, domain:, event:, seconds:, humanized: }` |
| `set_deadline` | `id:, at:, description: ''` | `{ success:, id:, at:, description: }` |
| `check_deadlines` | (none) | `{ success:, overdue:, upcoming:, urgency: }` |
| `update_time_perception` | `tick_results: {}` | `{ success:, dilation:, urgency: }` — extracts arousal from emotional_evaluation, cognitive_load from elapsed/budget ratio |
| `predict_event` | `domain:, event:` | `{ success:, domain:, event:, predicted_at:, confidence: }` |
| `temporal_patterns` | (none) | `{ success:, patterns:, count: }` — all TemporalPattern summaries |
| `temporal_stats` | (none) | Total events tracked, deadlines count, active patterns, current dilation |

### `update_time_perception` Details

Reads from `tick_results`:
- `arousal` from `tick_results.dig(:emotional_evaluation, :arousal)` (defaults to 0.5)
- `cognitive_load` computed as `elapsed_ticks / budget_ticks` ratio from `tick_results.dig(:timing)` (defaults to 0.5)

### `elapsed_since` humanization

`humanize_duration(seconds)`: < 60 = "Xs", < 3600 = "Xm Xs", < 86400 = "Xh Xm", else "Xd Xh"

## Integration Points

- **lex-tick / lex-cortex**: `update_time_perception` wired as a tick phase handler; `mark_event` called from any phase that registers timestamped activity
- **lex-emotion**: arousal from emotional_evaluation drives subjective time dilation via `update_time_perception`
- **lex-temporal-discounting**: objective elapsed time from this extension feeds into delay calculations for the discounting model
- **lex-volition**: deadline urgency from `check_deadlines` feeds into the urgency drive computation in DriveSynthesizer
- **lex-prediction**: `predict_event` outputs can be used as forward-model predictions fed back into lex-prediction

## Development Notes

- `temporal_store` is a private memoized accessor (`@temporal_store ||= Helpers::TemporalStore.new`) on the runner
- Timestamps are stored as `Time` objects; `elapsed_since` returns a float in seconds
- `classify_pattern` uses coefficient of variation (std_dev / mean) for periodicity; CV < 0.3 is a well-established empirical threshold for regularity
- Dilation range 0.5–2.0 means time appears to pass at half to double its objective rate based on arousal/load
- `predict_next` returns `nil` for `:sparse` pattern; callers must guard against nil predicted_at
