#include "cli.hpp"

std::string extract_json_string(std::string msg, std::string field)
{
	size_t i = msg.find(field);
	if (i == std::string::npos)
		return "";
	i += field.size();
	while (msg[i] == '\"' || msg[i] == ' ' || msg[i] ==  ':')
		i++;
	size_t len = 1;
	while (msg[i + len] && msg[i + len] != '"')
		len++;
	return (msg.substr(i, len));
}