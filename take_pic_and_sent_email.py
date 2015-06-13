import pygame.camera
import os
import smtplib
from email.mime.text import MIMEText
from email.mime.image import MIMEImage
from email.mime.multipart import MIMEMultipart


def take_pic():
	pygame.init()
	pygame.camera.init()

	cam = pygame.camera.Camera("/dev/video0",(640,480))
	cam.start()
	im = cam.get_image()
	pygame.image.save(im,"image.jpg")

def delete_file(file_name):
	if not os.path.isfile(file_name):
		print "File removed"
	else:
		os.remove(file_name)
		print "Remove success!!"

def send_email():
	to = 'tuantv_57@vnu.edu.vn'
	gmail_user = 'tikitaka.yugi@gmail.com'
	gmail_pwd = 'Tuan12345'

	smtpserver = smtplib.SMTP("smtp.gmail.com",587)
	smtpserver.ehlo()
	smtpserver.starttls()
	smtpserver.ehlo
	smtpserver.login(gmail_user, gmail_pwd)


	msg = MIMEMultipart()
	msg['Subject'] = 'Send email with image'
	msg['From'] = gmail_user
	msg['To'] = to

	text = MIMEText("This is an image which has taken by pygame camera!")
	msg.attach(text)
	img_data = open("image.jpg", 'rb').read()
	image = MIMEImage(img_data, name = os.path.basename("image.jpg"))
	msg.attach(image)

	smtpserver.sendmail(gmail_user, to, msg.as_string())
	smtpserver.close()
	print "Done!"


if __name__ == '__main__':
	take_pic()
	send_email()
	delete_file("image.jpg")