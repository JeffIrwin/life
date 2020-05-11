
#include <stdio.h>
#include <iostream>

#include <colormapper.h>

static ColorMap c;

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

