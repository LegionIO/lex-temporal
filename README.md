# lex-temporal

Temporal perception and time reasoning for LegionIO's cognitive architecture.

## Overview

Models the brain's time perception mechanisms — elapsed awareness, temporal urgency, pattern detection, deadline tracking, and subjective time dilation. Without temporal awareness, the agent treats a 5-second-old event identically to a 5-hour-old one.

## Components

- **TimePerception**: Tracks elapsed time since events, computes temporal urgency, detects overdue items
- **TemporalPattern**: Recognizes recurring temporal patterns (circadian, periodic, bursty)
- **TemporalStore**: Manages event timestamps, deadlines, and temporal pattern history

## Installation

```ruby
gem 'legion-extensions-temporal'
```

## Usage

```ruby
client = Legion::Extensions::Temporal::Client.new

# Mark an event
client.mark_event(event: :task_completed, domain: :deployment)

# Check elapsed time
client.elapsed_since(event: :task_completed)

# Set a deadline
client.set_deadline(id: :release, at: Time.now + 3600)

# Get temporal urgency
client.temporal_urgency
```
