🔧 QY-BERN Ultimate System Monitor Pro
A Cyberpunk-Themed System Monitor with Telegram Alerts

![image alt](https://github.com/NullH3xx/Qybern/blob/main/demo.PNG?raw=true)
🌟 Features

   ✅ Real-Time Monitoring (CPU, RAM, Disk, Temperature, Network)

   ✅ Telegram Alerts (Instant notifications when thresholds are exceeded)

   ✅ OTP Verification (Secure bot setup)

   ✅ Custom Thresholds (Set warning/critical levels)

   ✅ Cyberpunk UI (Animated terminal interface)

   ✅ Systemd Service (Runs 24/7 in the background)

   ✅ Logging (/var/log/nullhexx_monitor.log)

📥 Installation

    1. Download the Script

         git clone https://github.com/NullH3xx/Qybern && cd Qybern
  
         chmod +x Qybern.sh 

         sudo ./Qybern.sh  # to run the script

![image alt](https://github.com/NullH3xx/Qybern/blob/main/sudo.PNG?raw=true)

3. (Optional) Run as a Background Service ✅

       sudo systemctl start nullhexx-monitor    # Start
   
       sudo systemctl stop nullhexx-monitor     # Stop
   
       sudo systemctl status nullhexx-monitor   # Check status

🤖 How to Get Telegram Bot Token & Chat ID

   Step 1: Create a Telegram Bot ✅

      1- Open Telegram and search for @BotFather (Official Bot Creator).

      2- Send /newbot and follow instructions:

          * Choose a name (e.g., MySystemAlertBot).

          * Choose a username (must end with bot, e.g., MySystemAlertBot_bot).

      3- Copy the API Token (e.g., 123456789:ABCdef_GHIJKLmnopQRSTUVwxyz).

   Step 2: Get Your Chat ID✅

      Method 1: Using userinfobot

         1- Search for @userinfobot on Telegram.

         2- Send /start.

         3- It will reply with your Chat ID (e.g., 123456789).
         
      Method 2: Manual Detection
      
         1- Add your bot to a group (or DM it).

         2- Visit this URL in a browser (replace BOT_TOKEN):

            # https://api.telegram.org/bot<BOT_TOKEN>/getUpdates

         3- Look for "chat":{"id":123456789} in the JSON response.

⚙️ Configuration

   After installation, the script stores settings in:

       /etc/nullhexx_monitor.conf

       # You can manually edit thresholds (CPU, RAM, etc.) here.

📜 Example Telegram Alert

   [image alt]()

📌 Troubleshooting

     Issue  :	Solution

     Bot not sending alerts	: Check if the bot is added to the chat.

     Invalid Chat ID : Re-run setup and verify the ID.

     Permission denied : Run with sudo.

 📢 Share & Support
 
    ⭐ Love this tool? Star the repo!

    🔗 GitHub: https://github.com/NullH3xx/

Follow me for more:

      🐦 Twitter (X): @nullh3xx

      📸 Instagram: @nullh3xx

      💼 LinkedIn: Abderrahmane Idrissi Mesbahi



   
      


