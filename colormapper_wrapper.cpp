
#include <stdio.h>
#include <iostream>

#include <colormapper.h>

static irwincolor::Map c;

extern "C" int load_colormap_(char* cfile, char* cmapname)
{
	int io = 0;

	std::string file = cfile;
	std::string mapname = cmapname;
	if (file != "" && mapname != "") io = c.load(file, mapname);

	return io;
}

extern "C" void map_(double& x, uint8_t* rgbo)
{
	//std::cout << "x = " << x << std::endl;

	std::vector<uint8_t> rgb = c.map(x);

	rgbo[0] = rgb[0];
	rgbo[1] = rgb[1];
	rgbo[2] = rgb[2];

	return;
}

extern "C" int writepng_(uint8_t* b, int& nx, int& ny, char* cf)
{
	// Can pix be constructed without copying every element of b?
	// May need to add alpha channel in Fortran.

	//std::vector<uint8_t> pix(b, b + 4 * nx * ny);
	std::vector<uint8_t> pix(4 * nx * ny);
	int j = 0;
	for (int i = 0; i < 4 * nx * ny; i++)
	{
		if ((i+1) % 4 != 0)
			pix[i] = b[j++];
			// or
			//   pix[j * 4/3] = b[j];
		else
			pix[i] = 255;
	}

	return irwincolor::savePng(pix, nx, ny, (std::string) cf);
}
