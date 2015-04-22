import pyscreenshot as ImageGrab
import os.path, time

# function to take a screenshot picture, which name is current time
def takeScreenShot():
    savedFolder = os.path.join(os.path.expanduser('~'), 'App', 'AutoScreenShot', '%s' % time.strftime("%d-%m-%Y"))
    if not os.path.exists(savedFolder):
        os.makedirs(savedFolder)
    fileName = os.path.join(savedFolder, '%s.png' % time.strftime("%H:%M:%S"))
    ImageGrab.grab().save(fileName)

#wait 60s after startup
time.sleep(60)

#take screenshot after every 30 minutes
while (1):
    takeScreenShot()
    time.sleep(1800)