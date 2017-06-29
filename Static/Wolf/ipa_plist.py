import sys, zipfile, biplist, re

def analyze_ipa_with_plistlib(ipa_path):
	ipa_file = zipfile.ZipFile(ipa_path)
	plist_path = find_plist_path(ipa_file)
	plist_data = ipa_file.read(plist_path)
	plist_root = biplist.readPlistFromString(plist_data)
	return plist_root

def find_plist_path(zip_file):
	name_list = zip_file.namelist()
	# print name_list
	pattern = re.compile(r'Payload/[^/]*.app/Info.plist')
	for path in name_list:
		m = pattern.match(path)
		if m is not None:
			return m.group()

print analyze_ipa_with_plistlib(sys.argv[1])["CFBundleVersion"]
