# Restaurant Booking Bot - Persistent Flow Example

A complete restaurant table booking system demonstrating Telega's persistent flow capabilities with database integration.

## Features Demonstrated

- 🍽️ **Multi-step conversational flows** - User registration and table booking with persistence
- 📊 **Database persistence** - PostgreSQL integration with flow state storage
- 🔄 **Flow resumption** - Continue conversations after interruptions
- ✅ **Input validation** - Robust error handling and user feedback
- 🗄️ **Real-time data** - Live table availability checking
- 🏗️ **Interactive Menus** - Advanced menu system using menu_builder with categories and pagination

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
- `/menu` - Browse restaurant menu with interactive categories
- `/book` - Make a table reservation
- `/my_bookings` - View your reservations
- `/help` - Show available commands

The bot guides users through multi-step flows that persist across bot restarts and handle interruptions gracefully.

### Menu System

The new `/menu` command demonstrates the `menu_builder` module capabilities:

- **Categorized browsing** - Browse by food categories (Appetizers, Main Courses, Pizza, etc.)
- **Pagination** - Large item lists automatically paginated
- **Navigation** - Smooth back/forward navigation between menu levels
- **Rich formatting** - Emojis, pricing, and item counts for better UX
- **Integration** - Seamlessly integrated with existing flows and database

Example menu structure:
```
🍽️ Restaurant Name Menu

🍽️ Food Categories
🥗 Appetizers (8 items)    🍖 Main Courses (12 items)
🍝 Pasta (10 items)        🍕 Pizza (15 items)
🍰 Desserts (6 items)      🥤 Beverages (20 items)

📋 Reservations
🍽️ Make Reservation       📋 My Bookings
```
