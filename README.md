# SubTube - YouTube Subtitle Downloader

<p align="center">
  <img src="static/image/icon128.png" alt="SubTube Logo" width="128" height="128">
</p>

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue)](https://github.com/Devehab/subtube)
[![Platform](https://img.shields.io/badge/Platform-Web-brightgreen)](https://github.com/Devehab/subtube)
[![Python](https://img.shields.io/badge/Python-3.6+-yellow)](https://github.com/Devehab/subtube)

SubTube is a powerful web application that allows users to download, view, and copy subtitles from YouTube videos in various formats. Built with Flask and modern web technologies, it offers a seamless experience for accessing subtitle content without requiring advanced technical knowledge.

![SubTube Screenshot](static/image/demo.gif)

## Table of Contents

- [Features](#-features)
- [Installation & Usage](#-installation--usage)
  - [Easy Installation (One-Line)](#easy-installation-one-line)
  - [Traditional Method](#traditional-method)
  - [Docker Method](#docker-method)
  - [Docker Compose Method](#using-docker-compose)
  - [Multi-Architecture Docker Build](#multi-architecture-docker-build)
- [How to Use](#-how-to-use)
- [Requirements](#-requirements)
- [Development](#-development)
- [Contributing](#-contributing)
- [License](#-license)
- [Author](#-author)

## ✨ Features

- 📝 **Multi-format Support**: Download subtitles in SRT, VTT, or TXT format
- 🌐 **Language Selection**: Support for all subtitle languages available on YouTube videos
- 📋 **RAW Text Display**: View and copy subtitle text directly in the browser without downloading
- 📱 **Responsive Design**: Works seamlessly on desktop and mobile devices
- 🔄 **Easy URL Pasting**: Paste button for quick URL input from clipboard
- 🎨 **Modern UI**: Clean and intuitive interface built with Tailwind CSS
- 🔒 **Cross-platform Compatibility**: Runs on all major operating systems via Docker
- 🚀 **Fast and Lightweight**: Minimal resource usage for optimal performance

## 🚀 Installation & Usage

### Easy Installation (One-Line)

For most systems, you can install SubTube with this one-line command:

```bash
curl -sSL https://raw.githubusercontent.com/Devehab/subtube/main/install.sh | bash
```

#### Automatic Background Installation

For completely automated installation that runs in the background (no input needed):

```bash
curl -sSL https://raw.githubusercontent.com/Devehab/subtube/main/install.sh | bash
```

This will:
- Install SubTube in your home directory (`~/subtube_app`)
- Run it in the background automatically
- Choose an available port (starting at 3012)
- Fall back to Python if Docker isn't available
- Display the URL when finished

To stop the background service:
```bash
pkill -f 'python.*app.py'
```

If you're on macOS and encounter permission issues, try:

```bash
curl -sSL https://raw.githubusercontent.com/Devehab/subtube/main/install.sh -o /tmp/install-subtube.sh && chmod +x /tmp/install-subtube.sh && /tmp/install-subtube.sh
```

When prompted, type `y` to continue with the Python installation if you don't have Docker installed.

### Traditional Method

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Devehab/subtube.git
   cd subtube
   ```

2. **Create and activate a virtual environment** (optional but recommended):
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

3. **Install required dependencies**:
   ```bash
   pip3 install -r requirements.txt
   ```

4. **Run the application**:
   ```bash
   python3 app.py
   ```

5. **Access the application**:
   Open your browser and navigate to `http://127.0.0.1:5000`

### Docker Method

#### Using Docker directly:

1. **Build the Docker image**:
   ```bash
   docker build -t subtube:latest .
   ```

2. **Run the container**:
   ```bash
   docker run -p 5000:5000 subtube:latest
   ```

3. **Access the application**:
   Open your browser and navigate to `http://localhost:5000`

#### Using Docker Compose:

1. **Start the service**:
   ```bash
   docker-compose up -d
   ```

2. **Access the application**:
   Open your browser and navigate to `http://localhost:5000`

3. **Stop the service**:
   ```bash
   docker-compose down
   ```

#### Multi-Architecture Docker Build:

Build and publish for both ARM64 (Apple Silicon/M1/M2) and AMD64 architectures:

1. **Enable BuildKit**:
   ```bash
   export DOCKER_BUILDKIT=1
   ```

2. **Create and use a multi-architecture builder**:
   ```bash
   docker buildx create --name mybuilder --use
   ```

3. **Build for multiple platforms**:
   ```bash
   docker buildx build --platform linux/amd64,linux/arm64 -t yourusername/subtube:latest .
   ```

4. **Build and push to Docker Hub** (optional):
   ```bash
   docker buildx build --platform linux/amd64,linux/arm64 -t yourusername/subtube:latest --push .
   ```

## 📋 How to Use

1. Enter a valid YouTube video URL in the input field (or use the paste button)
2. Click "Fetch Subtitles" to retrieve available subtitle languages
3. Select your preferred language from the options
4. Choose your preferred subtitle format (SRT, VTT, or TXT) to download
5. Alternatively, click "Show RAW Text" to view and copy the subtitles directly in the browser

## 🔧 Requirements

- Python 3.6+
- Flask
- youtube_transcript_api
- requests
- Internet connection

For Docker deployment:
- Docker Engine 19.03.0+
- Docker Compose 1.27.0+ (for compose method)

## 🧰 Development

SubTube is built with the following technologies:
- **Backend**: Python with Flask framework
- **Frontend**: HTML, JavaScript, and Tailwind CSS
- **API**: youtube_transcript_api for fetching YouTube subtitles
- **Containerization**: Docker for cross-platform deployment

## 🤝 Contributing

Contributions are welcome! Feel free to fork the repository and submit pull requests. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📜 License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

- **Ehab Kahwati** - [GitHub](https://github.com/Devehab)

---

Made with ❤️ by Ehab Kahwati
