# 📘 1stKLGB Hub: Streamlined Management & Communication Centre

This web application was developed as part of a Final Year Project for Universiti Teknologi Malaysia (UTM) to support the **1st Kuala Lumpur Girls’ Brigade Malaysia (1stKLGB)**. It streamlines operations such as membership tracking, attendance, scheduling, announcements, and awards management for officers, squad leaders, girls, and parents.

---

## 📂 Project Structure

```
lib/
├── main.dart                      # App entry point
├── pages/                         # All screen/page files
├── theme/                         # Centralised app theming
└── widgets/                       # Reusable UI components (e.g., buttons, headers)
```

---

## ✨ Key Features

| Module | Description |
|--------|-------------|
| **Membership & Attendance** | Registration, profile management, squad assignment, weekly & sectional attendance. |
| **Communication & Scheduling** | Announcement board with attachments, annual calendar view. |
| **Awards & Promotions** | Assign and view awards (core, service, elective) and leadership promotions. |
| **Role-Based Dashboards** | Customised dashboards for Admin, Officer, Squad Leader, and Girl/Parent. |
| **Authentication** | Email/password login with role-based redirection. |

---

## 🚀 Technologies Used

- **Flutter Web** (Dart)
- **Firebase** (Authentication, Firestore, Storage)
- **VS Code**, **Draw.io** (for architecture/design diagrams)
- **Figma** (UI reference)

---

## 🔑 Roles & Navigation

| Role | Access Rights |
|------|----------------|
| **Officer** | Full CRUD access to members, awards, announcements, and calendar |
| **Squad Leader** | Attendance marking, viewing schedules & announcements |
| **Girl/Parent** | Read-only access to calendar, awards, and announcements |

---

## 🛠 How to Run (Locally)

1. **Install Flutter SDK (stable channel)**
2. **Clone this repo or unzip the folder**
3. Run:
   ```bash
   flutter pub get
   flutter run -d chrome
   ```
4. Ensure Firebase config (`firebase_options.dart`) is set up for Web.

---

## 📸 Screens Included

- `landing_page.dart`, `login_page.dart`, `signup_page.dart`
- `admin_dashboard_page.dart`, `officer_dashboard_page.dart`, `squad_leader_dashboard_page.dart`, `girl_parent_dashboard_page.dart`
- `award_page.dart`, `award_list_page.dart`
- `promotion_list_page.dart`
- `announcement_list_page.dart`, `announcement_page.dart`
- `annual_calendar_overview_page.dart`, `annual_calendar_page.dart`
- `full_attendance_list_page.dart`, `sectional_attendance_page.dart`, `squad_attendance_list_page.dart`

---

## 👤 Developer

**Name**: Shalominy Phang  
**Institution**: Universiti Teknologi Malaysia (UTM), MJIIT  
**Supervisors**:  
- Assoc. Prof. Dr. Masitah Ghazali (FYP 1)  
- Dr. Siti Nur Khadijah Aishah Ibrahim (FYP 2)