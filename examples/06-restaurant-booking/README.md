# Restaurant Booking Bot - Persistent Flow Example

A complete restaurant table booking system demonstrating Telega's persistent flow capabilities with database integration.

## Features Demonstrated

- 🍽️ **Multi-step conversational flows** - User registration and table booking with persistence
- 📊 **Database persistence** - PostgreSQL integration with flow state storage
- 🔄 **Flow resumption** - Continue conversations after interruptions
- ✅ **Input validation** - Robust error handling and user feedback
- 🗄️ **Real-time data** - Live table availability checking

## Setup

### Prerequisites
- Docker and Docker Compose
- Gleam
- Telegram Bot Token from @BotFather

### Quick Start

1. Configure environment in `.env` file

2. Start database:
```bash
docker-compose up -d
```

3. Run bot:
```bash
gleam deps download
gleam run
```

## Usage

- `/start` - Register your profile
- `/book` - Make a table reservation
- `/mybookings` - View your reservations
- `/help` - Show available commands

The bot guides users through multi-step flows that persist across bot restarts and handle interruptions gracefully.
