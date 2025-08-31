# purpose for this script is to practice hash and file creation with python
# hashlib lets you create hashes
# secrets is used for cryptographically secure random numbers
# from the library pathlib, Path is a way to handle filesystem paths. You can also use import os
import hashlib
import secrets
from pathlib import Path

# desktop variable is assigned as Path.home() which gives the user's home directory with / desktop appending to the home path. so it goes from /home/username to /home/username/Desktop with the append
desktop = Path.home() / "Desktop"
filepath = desktop / "hashes.txt"

# function make_hash generates 32 random bytes and passes them into hashlib to create the hash and converts it to a hex. its only returning 16 characters but that can be adjusted.
def make_hash():
    random_bytes = secrets.token_bytes(32)
    hash_object = hashlib.sha256(random_bytes)
    return hash_object.hexdigest()[:16]

# calls the function twice
hash1 = make_hash()
hash2 = make_hash()

# with ensures the file is closed automatically. open opens the file located at filepath
with open(filepath, 'w') as file:
    file.write(f"{hash1}\n{hash2}\n")

# prints the path of where the file makes the hashes. this is to have your hashes saved on your desktop instead of printing to your terminal that can protect against shoulder surfing and also malware such as keyloggers
print(f"Hashes written to: {filepath}")
