#!/usr/bin/env python3

# Adapted from https://gist.github.com/gautamk/3864756
#
# Changes:
# - Updated to Python 3
# - Added feature to allow downloading via given name

import sys
import json
import urllib.request

data = {}
raw_data = "raw_data"
parsed_data = "parsed_data"
file_names = "file_names"


def exit_with_help():
	sys.exit("----")


def load():
	with urllib.request.urlopen(
		"https://api.github.com/repos/github/gitignore/git/trees/HEAD"
	) as response:
		data[raw_data] = response.read()
	data[parsed_data] = json.loads(data[raw_data])
	data[file_names] = [
		entry["path"].split(".gitignore")[0] for entry in data[parsed_data]["tree"]
	]


def help():
	print(
		"""
NAME
	   download_gitignore - download .gitignore files from github.com/github/gitignore repo

USAGE
	download_gitignore.py [list|download] [number or name] [destination path]

	The number or name is matched from the "list" output, e.g.:
		download_gitignore.py download 5 ./.gitignore
		download_gitignore.py download Python ./.gitignore
"""
	)


def list_files():
	load()
	for i, name in enumerate(data[file_names]):
		print(i, ":", name)
	print(
		"""
USE
	download_gitignore.py [download|d] [number or name] [path]
	to download a file
	"""
	)


def resolve_index(identifier):
	if identifier.isdigit():
		return int(identifier)
	matches = [
		i for i, name in enumerate(data[file_names]) if name.lower() == identifier.lower()
	]
	if not matches:
		sys.exit('No template named "{}" found. Run "list" to see options.'.format(identifier))
	if len(matches) > 1:
		sys.exit(
			'Multiple templates match "{}": {}. Use the number instead.'.format(
				identifier, ", ".join(data[file_names][i] for i in matches)
			)
		)
	return matches[0]


def download(identifier, path):
	load()
	index = resolve_index(identifier)
	base_url = "https://raw.githubusercontent.com/github/gitignore/master/"
	file_name = data[file_names][index] + ".gitignore"
	url = base_url + file_name
	print("Downloading", url, "to", path)
	urllib.request.urlretrieve(url, path)


def main():
	try:
		if sys.argv[1] == "help":
			help()
			exit_with_help()
		elif sys.argv[1] in ("list", "l"):
			list_files()
		elif sys.argv[1] in ("download", "d"):
			download(sys.argv[2], sys.argv[3])
		else:
			help()
			exit_with_help()
	except IndexError:
		help()
		exit_with_help()


if __name__ == "__main__":
	main()
