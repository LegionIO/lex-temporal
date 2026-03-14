# lex-temporal

Temporal perception and time management for LegionIO cognitive agents. Tracks elapsed time, deadlines, subjective time dilation, and recurring event patterns.

## What It Does

`lex-temporal` gives cognitive agents a sense of time. It records when events happen, measures how long ago they occurred, tracks deadlines with urgency scoring, models how arousal and cognitive load warp subjective time perception, and identifies whether recurring events are periodic, bursty, irregular, or sparse.

- **Event timing**: per-domain, per-event timestamp history
- **Deadlines**: up to 50 deadlines with urgency scoring (overdue through far_future)
- **Subjective dilation**: `dilation` factor 0.5–2.0, updated via EMA from arousal + cognitive load
- **Pattern detection**: periodic (CV < 0.3), bursty (clustered intervals), irregular, sparse
- **Next-event prediction**: confidence-scored estimates based on pattern type

## Usage

```ruby
require 'legion/extensions/temporal'

client = Legion::Extensions::Temporal::Client.new

# Mark events
client.mark_event(domain: :coding, event: :commit)
# => { count: 1, elapsed_since: nil }

sleep 5

client.mark_event(domain: :coding, event: :commit)
# => { count: 2, elapsed_since: 5.0 }

# Elapsed time with humanized format
client.elapsed_since(domain: :coding, event: :commit)
# => { seconds: 5.0, humanized: '5s' }

# Set a deadline
client.set_deadline(
  id: 'sprint_end',
  at: Time.now + 3600,
  description: 'Sprint closes'
)

# Check deadlines
client.check_deadlines
# => { overdue: [], upcoming: [{ id: 'sprint_end', urgency: 0.05 }], urgency: 0.05 }

# Predict next occurrence based on pattern
client.predict_event(domain: :coding, event: :commit)
# => { predicted_at: ..., confidence: 0.8 }

# Per-tick update (reads arousal + cognitive_load from tick_results)
client.update_time_perception(tick_results: tick_output)
# => { dilation: 1.2, urgency: 0.05 }

# Temporal stats
client.temporal_stats
# => { total_events_tracked:, deadlines_count:, active_patterns:, current_dilation: }
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
