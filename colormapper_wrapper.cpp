
#include <stdio.h>
#include <iostream>

#include <colormapper.h>

static ColorMap c;

extern "C" int load_colormap_()
{
	std::string file = "../submodules/colormapper/submodules/colormaps/ColorMaps5.6.0.json";
	std::string mapname = "Plasma (matplotlib)";

	c.paraView = true;
	c.imap = -1;
	c.inv = false;
	c.load(file, mapname);

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

