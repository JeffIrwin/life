
#include <stdio.h>
#include <iostream>

#include <colormapper.h>

static ColorMap c;

extern "C" int load_colormap_(char* cfile, char* cmapname)
{
	std::string file = cfile;
	std::string mapname = cmapname;

	c.paraView = (file != "" && mapname != "");
	c.imap = -1;
	c.inv = false;

	if (c.paraView) c.load(file, mapname);

	return 0;
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

