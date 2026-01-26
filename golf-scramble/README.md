# Golf Scramble

A live golf scramble scoring app with team management, leaderboard, chat, and media sharing.

## Features

- **Team Management**: Create and manage multiple teams
- **Live Scoring**: Real-time score entry for each hole
- **Leaderboard**: Automatically ranked standings with to-par calculations
- **Smack Talk Chat**: In-app messaging between teams
- **Media Sharing**: Upload photos and videos from each hole
- **Course Par Setup**: Customize par for each hole or use standard presets (Par 70/72)
- **Responsive Design**: Works on desktop and mobile devices

## Getting Started

### Prerequisites

- Node.js 18 or higher
- npm or yarn

### Installation

```bash
cd golf-scramble
npm install
```

### Development

Start the development server:

```bash
npm run dev
```

The app will open at `http://localhost:3000`.

### Build for Production

```bash
npm run build
```

The built files will be in the `dist/` directory.

### Preview Production Build

```bash
npm run preview
```

## Usage

1. **Setup**: Add team names and configure course pars
2. **Select Team**: Choose your team to start scoring
3. **Score Entry**: Enter scores for each hole as you play
4. **View Leaderboard**: See real-time standings
5. **Chat**: Send messages to other teams
6. **Share Media**: Upload photos/videos from great shots

## Data Storage

By default, the app uses localStorage for data persistence. This works great for single-device use. For multi-device sync, you can integrate a backend service like Firebase, Supabase, or your own API by modifying the `src/storage.js` file.

## Tech Stack

- React 18
- Vite
- Tailwind CSS
- Lucide React (icons)

## License

MIT
