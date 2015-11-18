import sys,smtplib
from email.mime.text import MIMEText


fp = open('desktop.ini', 'rb')
message = fp.read()
fp.close()

to = 'tuantv_57@vnu.edu.vn'
gmail_user = 'tikitaka.yugi@gmail.com'
gmail_pwd = 'Password'

smtpserver = smtplib.SMTP("smtp.gmail.com",587)
smtpserver.ehlo()
smtpserver.starttls()
smtpserver.ehlo
smtpserver.login(gmail_user, gmail_pwd)

header = 'To:' + to + '\n' + 'From: ' + gmail_user + '\n' + 'Subject:send data of file desktop.ini \n'
print header
msg = header + message

smtpserver.sendmail(gmail_user, to, msg)
print 'done!'
smtpserver.close()
