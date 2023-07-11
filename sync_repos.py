import subprocess
import repo_loc

for repo in repo_loc.repo_locs:
    # print(repo)
    process = subprocess.Popen(["cd", repo, '&&', "pwd"], shell=True)
    # Read the output and error
    output, error = process.communicate()

    # Print the output and error
    print("Output:", output.decode())
    print("Error:", error.decode())
    subprocess.run(["pwd"])
# subprocess.run(["ls", "-l"])