photokit-nsphotolibrary.so: photokit-nsphotolibrary.o
	gcc -shared -framework Cocoa -framework Photos -o photokit-nsphotolibrary.so photokit-nsphotolibrary.o
photokit-nsphotolibrary.o: photokit-nsphotolibrary.m
	gcc -Wall -c photokit-nsphotolibrary.m
