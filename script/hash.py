#!/usr/bin/python

import os
import sys
import json
import hashlib

def get_files_list(directory, update_url): 
	file_list={}
	os.chdir(directory)
	for root, dirs, files in os.walk('.'):
		for file in files:
			file_name = (root.replace('\\','/') + '/' + file).replace('./','')
			file_hash = checksum(file_name)
			file_size = os.path.getsize(file_name)
			file_list[file_name] = {'file_hash':file_hash, 'file_size':file_size}
	return(file_list)

def checksum(file_name, hash_factory=hashlib.md5, chunk_num_blocks=128):
	h = hash_factory()
	with open(file_name,'rb') as f: 
		while chunk := f.read(chunk_num_blocks*h.block_size): 
			h.update(chunk)
	return h.hexdigest()

def save_json(jsons, file):
	with open(file, 'w', encoding="utf-8") as f:
		f.write(json.dumps(jsons, indent=2, ensure_ascii=False))

def read_version(directory, file):
	os.chdir(directory)
	with open(file, 'r', encoding="utf-8") as f:
		return f.read().split("LocalVersion=")[1].split("\n")[0]
		
if __name__ == '__main__':
	version_file = 'version.ini'
	branch_name = sys.argv[1]
	info_json = {}
	info_json['name'] = 'VupSlash'
	info_json['version'] = read_version(f'../{branch_name}/',version_file)
	info_json['description'] = 'A Sanguosha like game but characters is vup'
	info_json['author'] = '萌龙少主'
	info_json['website'] = 'https://vupslash.icu'
	info_json['source_url'] = f'https://github.com/shadlc/VupSlashSource/raw/{branch_name}/main/'
	info_json['files'] = get_files_list(f'../{branch_name}/', info_json['source_url'])
	json_name = 'hash_list.json'
	os.chdir('../web')
	save_json(info_json, json_name)
