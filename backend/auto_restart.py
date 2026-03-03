import subprocess
import time

while True:
    print("Starting Flask server...")
    try:
        # Start the Flask app
        process = subprocess.Popen(["python", "run.py"])

        # Wait until the Flask server stops (crash or manual stop)
        process.wait()

        print("Flask server stopped or crashed.")
    except Exception as e:
        print(f"Error occurred: {e}")

    print("Restarting Flask server in 2 seconds...\n")
    time.sleep(2)