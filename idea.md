
Create a YouTube subtitle downloader web application using **Python and Flask**. called **SubTube**. The website should allow users to enter a YouTube video URL and download available subtitles in different formats (**SRT, VTT, and TXT**). The application should:
 
 - Use **Flask** as the backend framework.
 - Use **youtube_transcript_api** to fetch subtitles.
 - Provide an intuitive **HTML frontend** using **Tailwind CSS** for styling.
 - Include **FontAwesome** for icons.
 - Use **Google Font 'Tajawal'** for a modern Arabic-friendly typography.
 - Display error messages if subtitles are unavailable.
 - Allow users to choose between different subtitle languages.
 - Have a **minimalist, responsive UI** with a simple search bar and download buttons.
 
 The output should be a **fully functional Flask project** with a structured directory:
 ```
 /youtube_subs_downloader
 ├── static/
 │   ├── css/
 │   ├── js/
 ├── templates/
 │   ├── index.html
 ├── app.py
 ├── requirements.txt
 ├── README.md
 ├── .gitignore
 ```

  ```
  <!-- Tailwind CSS -->
    <link href="https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css" rel="stylesheet">
    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css">
    <!-- Google Font -->
    <link rel="preconnect" href="https://fonts.gstatic.com">
    <link href="https://fonts.googleapis.com/css2?family=Tajawal:wght@400;500;700&display=swap" rel="stylesheet">
 ```

 The **`app.py`** should:
 - Handle form input for the **YouTube video URL**.
 - Extract subtitles using **youtube_transcript_api**.
 - Convert and serve the subtitle files dynamically.
 - Render the results with a **Jinja2 template**.
 
 The **frontend (`index.html`)** should:
 - Have a **modern design** with Tailwind CSS.
 - Include a **search bar** where users enter the YouTube URL.
 - Display available subtitle languages dynamically.
 - Offer **buttons to download subtitles** in different formats.
 - Include **error handling** for invalid URLs or unavailable subtitles.
 - Have **a responsive layout** that works on mobile and desktop.
 
 Ensure the project includes a **requirements.txt** file with:
 ```
 Flask
 youtube_transcript_api
 requests
 ```
 
 Generate **production-ready** Flask code and templates.


