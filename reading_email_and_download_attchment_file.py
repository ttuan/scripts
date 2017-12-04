__author__ = 'tuan'

# Be the change you want to see in the world

# Just download attachment file
import imaplib
import email
import os, time


host = 'imap.gmail.com'
user = 'youemail@gmail.com'
password = 'your password'


save_dir = 'D:/images/%s' % time.strftime("%d-%m-%Y")
if not os.path.exists(save_dir):
	os.makedirs(save_dir)


def download_attach_file():
	# login and select inbox
	mail = imaplib.IMAP4_SSL(host)
	mail.login(user, password)
	mail.select("INBOX")

	# filter: all file have attachment, is png file, from: tuantv.nhnd@gmail.com and you unread it
	res, data = mail.uid('search', None, 'X-GM-RAW',
						 'has:attachment filename:png in:inbox from:abc@gmail.com label:unread')

	# check if you have new email, download attachment file, if not, exit
	if data[0] == '':
		print "You have no new mail"
		mail.close()
	else:
		mail_ids = data[0].split()
		# read lasted email (mail_ids[-1])
		res, data = mail.uid('fetch', mail_ids[-1], 'RFC822')
		m = email.message_from_string(data[0][1])

		if m.get_content_maintype() == 'multipart':
			for part in m.walk():
				if part.get_content_maintype() == 'multipart':
					continue
				if part.get('Content-Disposition') is None:
					continue

				fileName = part.get_filename()
				att_path = os.path.join(save_dir, fileName)

				if not os.path.isfile(att_path):
					fp = open(att_path, 'wb')
					fp.write(part.get_payload(decode=True))
					fp.close()
					print "Saved"

if __name__ == '__main__':
	download_attach_file()
