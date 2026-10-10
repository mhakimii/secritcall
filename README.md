# SecritCall - Full VoIP System

سیستم کامل سانترال VoIP با پنل وب (FreePBX + Asterisk)

## نصب با یک دستور (Ubuntu 24.04 / 26.04)

به عنوان root این دستور را اجرا کنید:

```bash
curl -fsSL https://raw.githubusercontent.com/mhakimii/secritcall/main/install.sh -o install.sh
chmod +x install.sh
./install.sh
```

یا:

```bash
wget -O install.sh https://raw.githubusercontent.com/mhakimii/secritcall/main/install.sh
chmod +x install.sh
./install.sh
```

---

## بعد از نصب

1. سرور را یکبار ریبوت کنید:
   ```bash
   reboot
   ```

2. آدرس پنل را در مرورگر باز کنید:
   ```
   http://IP-سرور/admin
   ```

3. یوزرنیم و پسورد ادمین را بسازید.

4. از منوی **Applications → Extensions** داخلی بسازید.

5. در Zoiper یا هر سافت‌فون دیگری با اطلاعات داخلی وصل شوید.

---

## اطلاعات مهم

- پسورد دیتابیس در فایل زیر ذخیره می‌شود:
  ```
  /root/secritcall-db-pass.txt
  ```

- اطلاعات کامل نصب:
  ```
  /root/secritcall-info.txt
  ```

## پورت‌های باز شده

| پورت          | کاربرد          |
|---------------|------------------|
| 80 / 443      | پنل وب           |
| 5060 TCP/UDP  | SIP              |
| 10000-20000   | RTP (صدا)        |

---

## امکانات سیستم

- داخلی نامحدود
- ترانک SIP
- صف تماس (Call Queue)
- منوی صوتی (IVR)
- ضبط مکالمات
- کنفرانس
- فکس
- گزارش‌گیری کامل (CDR)
- سازگار با Zoiper، MicroSIP، Linphone و ...

---

ساخته شده برای پروژه SecritCall
