import os
import ffmpeg

DEFAULT_INPUT_FOLDER = 'input'
DEFAULT_OUTPUT_FOLDER = 'output'

def combine_video_and_audio(video_filename, audio_filename, output_filename):
    print(f"Combining video: {video_filename} with audio: {audio_filename} into {output_filename}")
    video_path = os.path.join(DEFAULT_INPUT_FOLDER, video_filename)
    audio_path = os.path.join(DEFAULT_INPUT_FOLDER, audio_filename)

    if not os.path.exists(video_path) or not os.path.exists(audio_path):
        print("Specified video or audio file does not exist.")
        return

    output_path = os.path.join(DEFAULT_OUTPUT_FOLDER, output_filename)
    
    # Create input streams for both video and audio
    video_stream = ffmpeg.input(video_path)
    audio_stream = ffmpeg.input(audio_path)
    
    # Combine streams and output
    stream = ffmpeg.output(video_stream, audio_stream, output_path, vcodec='copy', acodec='aac')
    
    # Run the ffmpeg command
    ffmpeg.run(stream)
    
    print(f"Done")

# Example usage
# combine_video_and_audio('video.mp4', 'audio.mp4', 'output_video.mp4')


