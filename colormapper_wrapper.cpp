
#include <stdio.h>
#include <iostream>

#include <colormapper.h>

static ColorMap c;

// TODO:  args for filename and map name
extern "C" int loadcolormap_()
{
	std::string file = "../submodules/colormapper/submodules/colormaps/ColorMaps5.6.0.json";
	std::string mapname = "Plasma (matplotlib)";

	c.paraView = true;
	c.imap = -1;
	c.inv = false;
	c.load(file, mapname);

	return 0;
}

extern "C" void map_(double& x, uint8_t& r, uint8_t& g, uint8_t& b)
{
	std::cout << "x = " << x << std::endl;

	std::vector<uint8_t> rgb = c.map(x);
	r = rgb[0];
	g = rgb[1];
	b = rgb[2];

	std::cout << "r = " << (int) r << std::endl;
	std::cout << "g = " << (int) g << std::endl;
	std::cout << "b = " << (int) b << std::endl;
	std::cout << std::endl;
	return;
}

