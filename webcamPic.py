import pygame.camera


pygame.init()
pygame.camera.init()

cam = pygame.camera.Camera("/dev/video0",(640,480))
cam.start()
im = cam.get_image()
pygame.image.save(im,"image.jpg")