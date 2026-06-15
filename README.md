# Student Attendance Tracker Deployment System

This system is an automated script designed to instantly build a structured development environment for checking student attendance records.

---

## How to Run the Script

To execute the automation layer and deploy your project workspace, copy and paste these exact commands into your terminal:

1. Navigate to the repository directory:
   cd ~/deploy_agent_gahamanyi-tech

2. Ensure the script has execution permissions:
   chmod +x setup_project.sh

3. Execute the deployment agent:
   ./setup_project.sh

4. Follow the terminal prompts:
   - Enter your workspace version suffix (for example: v1)
   - Input your threshold compliance percentages when prompted (for example: 80 and 50)

---

## How to Trigger the Archive Feature

The script features a built-in safety cleanup routine that triggers automatically during unexpected system interruptions:

1. Launch the script using the standard command: ./setup_project.sh
2. While the script is running and waiting for you to type an input, press Ctrl + C on your keyboard.
3. This sends a system interrupt signal (SIGINT).

The Result: The script instantly catches this interrupt, stops the installation, compresses any partial data into a backup recovery file named attendance_tracker_crash_test_archive.tar.gz, and completely purges the messy, unverified directories from your disk to leave your workspace perfectly clean.
