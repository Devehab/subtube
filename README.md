# SubTube - YouTube Subtitle Downloader

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue)](https://github.com/Devehab/subtube)
[![Platform](https://img.shields.io/badge/Platform-Web-brightgreen)](https://github.com/Devehab/subtube)
[![Python](https://img.shields.io/badge/Python-3.6+-yellow)](https://github.com/Devehab/subtube)

SubTube is a powerful web application that allows users to download, view, and copy subtitles from YouTube videos in various formats. Built with Flask and modern web technologies, it offers a seamless experience for accessing subtitle content without requiring advanced technical knowledge.

![SubTube Screenshot](https://via.placeholder.com/800x400?text=SubTube+Screenshot)

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

### Traditional Method

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Devehab/subtube.git
   cd subtube
   ```

2. **Install required dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Run the application**:
   ```bash
   python app.py
   ```

4. **Access the application**:
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
