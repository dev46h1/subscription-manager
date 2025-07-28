# 📱 Subscription Manager

A simple and elegant mobile app to track all your subscription services and never miss a renewal date again!

## 🎯 What Does This App Do?

**Subscription Manager** helps you keep track of all your monthly subscriptions like Netflix, Spotify, Adobe Creative Suite, and more. It's like having a personal assistant that reminds you when your subscriptions are about to renew, so you can:

- **Never get surprised** by unexpected charges
- **Cancel subscriptions** you no longer need before they renew  
- **See exactly how much** you're spending on subscriptions each month
- **Get notifications** 1 day before and on renewal day

## ✨ Key Features

### 📊 **Track Your Spending**
- See your total monthly and yearly subscription costs at a glance
- View spending breakdown by category (Entertainment, Software, Gaming, etc.)
- Beautiful visual summary on the home screen

### 🔔 **Smart Notifications**
- Get reminded 1 day before renewal
- Get notified on the actual renewal day
- Notifications work even when the app is closed
- Never miss another subscription renewal

### 📝 **Easy Management**
- Add new subscriptions in seconds
- Edit existing subscriptions anytime
- Delete subscriptions you no longer need
- Organize by categories for better tracking

### 🎨 **User-Friendly Design**
- Clean, modern interface
- Color-coded cards show urgent renewals
- Easy-to-read subscription details
- Intuitive navigation

## 🚀 Getting Started

### For Users (Non-Developers)

1. **Download & Install**: Get the app from your app store or ask a developer to build it for you
2. **Open the app**: Launch "Subscription Manager" 
3. **Add your first subscription**: Tap the "+" button and fill in:
   - Service name (e.g., "Netflix")
   - Monthly cost (e.g., "199")
   - Currency (e.g., "INR")
   - Next renewal date
   - Category (e.g., "Entertainment")
4. **Enable notifications**: Allow the app to send you notifications when prompted
5. **You're all set!** The app will now track your subscriptions and remind you before renewals

### For Developers

#### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Android Studio or VS Code
- Android device/emulator or iOS device/simulator

#### Installation
```bash
# Clone the repository
git clone <repository-url>
cd subscription_manager

# Install dependencies
flutter pub get

# Run the app
flutter run
```

#### Project Structure
```
lib/
├── main.dart                 # App entry point
├── models/
│   └── subscription.dart     # Subscription data model
├── providers/
│   └── subscription_provider.dart  # State management
├── screens/
│   ├── home_screen.dart      # Main dashboard
│   └── add_edit_screen.dart  # Add/edit subscriptions
├── services/
│   ├── database_helper.dart  # SQLite database operations
│   └── notification_service.dart # Local notifications
└── widgets/
    └── subscription_card.dart # Individual subscription display
```

## 🛠️ Technical Details

### Built With
- **Flutter** - Cross-platform mobile framework
- **SQLite** - Local database for storing subscriptions
- **Provider** - State management
- **Local Notifications** - Reminder system
- **Material Design 3** - Modern UI components

### Key Dependencies
- `sqflite` - Local database
- `flutter_local_notifications` - Notification system
- `provider` - State management
- `intl` - Date formatting
- `timezone` - Scheduled notifications

### Permissions Required
- **Notifications** - To send renewal reminders
- **Boot Complete** - To reschedule notifications after device restart
- **Exact Alarms** - For precise notification timing
- **Wake Lock** - To ensure notifications work when device is sleeping

## 📱 How to Use

### Adding a Subscription
1. Tap the **"+ Add Subscription"** button
2. Fill in the details:
   - **Name**: What service is it? (Netflix, Spotify, etc.)
   - **Amount**: How much do you pay monthly?
   - **Currency**: Your local currency
   - **Category**: What type of service is it?
   - **Renewal Date**: When does it renew next?
   - **Notes**: Any additional info (optional)
3. Tap **"Add Subscription"**

### Managing Subscriptions
- **View all subscriptions** on the home screen
- **Tap any subscription** to edit its details
- **Delete subscriptions** using the trash icon
- **See spending summary** by tapping the insights icon

### Understanding the Display
- **Green cards**: Subscriptions with plenty of time left
- **Yellow cards**: Renewals coming up within a week
- **Orange cards**: Renewals in 2-3 days
- **Red cards**: Renewing today or overdue

## 🔧 Troubleshooting

### Notifications Not Working?
1. Check that notification permissions are enabled in your device settings
2. Make sure the app isn't being killed by battery optimization
3. Verify the renewal dates are set correctly

### App Crashes?
1. Clear the app cache
2. Restart your device
3. Reinstall the app if problems persist

### Data Not Saving?
1. Ensure you have sufficient storage space
2. Check if the app has necessary file permissions

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. **Report bugs** - Found something broken? Let us know!
2. **Suggest features** - Have ideas for improvements?
3. **Submit code** - Fork the repo and create pull requests
4. **Improve documentation** - Help make this README even better

### Development Setup
```bash
# Fork the repository
# Clone your fork
git clone <your-fork-url>

# Create a feature branch
git checkout -b feature/amazing-feature

# Make your changes
# Test thoroughly

# Commit and push
git commit -m "Add amazing feature"
git push origin feature/amazing-feature

# Create a Pull Request
```

## 📄 License

This project is open source. Feel free to use, modify, and distribute as needed.

## 🆘 Support

Having trouble? Here's how to get help:

- **Check this README** for common solutions
- **Search existing issues** in the repository
- **Create a new issue** with detailed information about your problem
- **Ask the community** for help

## 🚀 Future Enhancements

We're constantly working to improve the app. Upcoming features include:

- 📈 **Spending trends and analytics**
- 🔄 **Automatic subscription detection**
- 💰 **Budget alerts and limits**
- 📤 **Export data to CSV**
- 🌙 **Dark mode theme**
- 🔐 **Data backup and sync**

---

**Made with ❤️ for people who want to take control of their subscription spending**

*Never get surprised by a subscription renewal again!*