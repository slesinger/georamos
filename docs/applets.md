# Applets

are ML code applications that are compiled to live in non-conflicting high memory. It gets executed from Georamos and when exited it will smoothly get back to Georamos. Using of such applets is uspposed to be smooth.

An Applet can use full screen resources, sprites, sound, anything, it is just responsible to put things as they were right before exiting back to Georamos.

When an applet is executed, it will always redownload its code from georam. It can, and it is advised, to store its state data in a seq file in georam.

Start address to execute applet must be the start of the code.