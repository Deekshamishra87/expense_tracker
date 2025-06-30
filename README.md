# 💸 Expense Tracker App

A modern Flutter app to track your expenses with clean visuals and smart AI budgeting suggestions using Gemini CLI.

---

## ✨ Features

- 📝 Add/edit/delete expenses
- 📊 Category-wise pie charts (`fl_chart`)
- 🧠 AI budgeting advice via Gemini CLI
- 🗓️ Calendar-based tracking
- 🎯 Filter by 1 day / 1 week / 1 month
- ⚠️ Set limit alerts with audio notification
- 🌗 Light/Dark Theme toggle
- 🗄️ Local storage using Hive
- 🔥 Firebase Integration (coming soon)

---

## ⚙️ Setup Instructions

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/Deekshamishra87/expense_tracker.git
cd expense_tracker
flutter pub get
```
### 2️⃣ Set Up Gemini CLI Local Server
This app uses a local Node.js server to generate AI suggestions via Gemini CLI.
```bash
cd openai-server
npm install
node index.js
```
📍 The server will run at:
http://<your-local-ip>:3000/ask

### 3️⃣ Configure Local IP in App
Open the following file:
```bash
lib/app_config.dart
```
Update the IP address:
```bash
class AppConfig {
  static const String aiServerUrl = 'http://192.168.xx.xx:3000/ask'; // Replace with your local IP
}
```

💡 How to find your IP address:

Windows: Run ipconfig in CMD → check IPv4 Address

Mac/Linux: Run ifconfig → check inet under your network

### 4️⃣ Run the Flutter App
Back to the root folder:
```bash
cd ..
flutter run
```
✅ Make sure your local Node server is still running in the background.

## 🙋‍♀️ Author

**Deeksha Mishra**  
🔗 [GitHub Profile](https://github.com/Deekshamishra87)
## 📄 License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT)

