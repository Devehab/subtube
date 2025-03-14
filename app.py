from flask import Flask, render_template, request, send_file, jsonify
from youtube_transcript_api import YouTubeTranscriptApi, TranscriptsDisabled, NoTranscriptFound
import re
import io
import os
import tempfile

app = Flask(__name__)

def extract_video_id(url):
    """Extract YouTube video ID from URL"""
    youtube_regex = (
        r'(https?://)?(www\.)?'
        r'(youtube|youtu|youtube-nocookie)\.(com|be)/'
        r'(watch\?v=|embed/|v/|.+\?v=)?([^&=%\?]{11})'
    )
    match = re.match(youtube_regex, url)
    return match.group(6) if match else None

def format_srt(transcript):
    """Convert transcript to SRT format"""
    srt_content = ""
    for i, segment in enumerate(transcript, 1):
        start_seconds = int(segment.start)
        start_ms = int((segment.start - start_seconds) * 1000)
        
        # Calculate end time
        duration = getattr(segment, 'duration', 0)
        end_time = segment.start + duration
        end_seconds = int(end_time)
        end_ms = int((end_time - end_seconds) * 1000)
        
        # Format timestamps
        start_time = f"{start_seconds//3600:02d}:{(start_seconds%3600)//60:02d}:{start_seconds%60:02d},{start_ms:03d}"
        end_time = f"{end_seconds//3600:02d}:{(end_seconds%3600)//60:02d}:{end_seconds%60:02d},{end_ms:03d}"
        
        # Format SRT entry
        srt_content += f"{i}\n{start_time} --> {end_time}\n{segment.text}\n\n"
    
    return srt_content

def format_vtt(transcript):
    """Convert transcript to VTT format"""
    vtt_content = "WEBVTT\n\n"
    for i, segment in enumerate(transcript, 1):
        start_seconds = int(segment.start)
        start_ms = int((segment.start - start_seconds) * 1000)
        
        # Calculate end time
        duration = getattr(segment, 'duration', 0)
        end_time = segment.start + duration
        end_seconds = int(end_time)
        end_ms = int((end_time - end_seconds) * 1000)
        
        # Format timestamps
        start_time = f"{start_seconds//3600:02d}:{(start_seconds%3600)//60:02d}:{start_seconds%60:02d}.{start_ms:03d}"
        end_time = f"{end_seconds//3600:02d}:{(end_seconds%3600)//60:02d}:{end_seconds%60:02d}.{end_ms:03d}"
        
        # Format VTT entry
        vtt_content += f"{start_time} --> {end_time}\n{segment.text}\n\n"
    
    return vtt_content

def format_txt(transcript):
    """Convert transcript to plain text format"""
    return "\n".join([segment.text for segment in transcript])

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/get_languages', methods=['POST'])
def get_languages():
    url = request.form.get('url')
    video_id = extract_video_id(url)
    
    if not video_id:
        return jsonify({'error': 'Invalid YouTube URL'}), 400
    
    try:
        transcript_list = YouTubeTranscriptApi.list_transcripts(video_id)
        available_languages = []
        
        for transcript in transcript_list:
            available_languages.append({
                'language_code': transcript.language_code,
                'language': transcript.language
            })
        
        return jsonify({'languages': available_languages})
    
    except (TranscriptsDisabled, NoTranscriptFound) as e:
        return jsonify({'error': 'No transcripts available for this video'}), 404
    except Exception as e:
        return jsonify({'error': f'An error occurred: {str(e)}'}), 500

@app.route('/get_raw_text', methods=['POST'])
def get_raw_text():
    url = request.form.get('url')
    language = request.form.get('language')
    
    video_id = extract_video_id(url)
    
    if not video_id:
        return jsonify({'error': 'Invalid YouTube URL'}), 400
    
    try:
        transcript_list = YouTubeTranscriptApi.list_transcripts(video_id)
        transcript = transcript_list.find_transcript([language])
        transcript_data = transcript.fetch()
        
        # Convert transcript to plain text
        raw_text = format_txt(transcript_data)
        
        return jsonify({'success': True, 'text': raw_text})
    
    except (TranscriptsDisabled, NoTranscriptFound) as e:
        return jsonify({'error': 'No transcripts available for this video'}), 404
    except Exception as e:
        return jsonify({'error': f'An error occurred: {str(e)}'}), 500

@app.route('/download', methods=['POST'])
def download_subtitles():
    url = request.form.get('url')
    language = request.form.get('language')
    format_type = request.form.get('format')
    
    video_id = extract_video_id(url)
    
    if not video_id:
        return jsonify({'error': 'Invalid YouTube URL'}), 400
    
    try:
        transcript_list = YouTubeTranscriptApi.list_transcripts(video_id)
        transcript = transcript_list.find_transcript([language])
        transcript_data = transcript.fetch()
        
        # Get video title for the filename
        video_title = f"subtitles_{video_id}"
        
        # Format subtitle according to requested type
        if format_type == 'srt':
            subtitle_content = format_srt(transcript_data)
            mimetype = 'text/plain'
            extension = 'srt'
        elif format_type == 'vtt':
            subtitle_content = format_vtt(transcript_data)
            mimetype = 'text/vtt'
            extension = 'vtt'
        else:  # txt format
            subtitle_content = format_txt(transcript_data)
            mimetype = 'text/plain'
            extension = 'txt'
        
        # Create a BytesIO object for sending the file
        subtitle_file = io.BytesIO(subtitle_content.encode('utf-8'))
        
        return send_file(
            subtitle_file,
            as_attachment=True,
            download_name=f"{video_title}.{extension}",
            mimetype=mimetype
        )
    
    except (TranscriptsDisabled, NoTranscriptFound) as e:
        return jsonify({'error': 'No transcripts available for this video'}), 404
    except Exception as e:
        return jsonify({'error': f'An error occurred: {str(e)}'}), 500

if __name__ == '__main__':
    app.run(debug=True, port=5000)
