To understand his this tool works, it is useful and recommended to read  [meg's README](https://github.com/tomnomnom/meg)

The process is divided in three parts. 

## 1. Before `meg`

This step focus on creating the files needed for running `meg`, which are : 
- a list of hosts
- a list of paths (named tokens in this tool)

**generateHosts.sh :**

- create the list of hosts. 

  1. Using a live list on github which is updated frequently : https://github.com/PeterDaveHello/url-shorteners.

  2. And it also uses https://wiki.archiveteam.org/index.php/URLTeam but the process is heavy (because it requires some manual pre-processing and work) for not so much result

  For each list, the script will check if they're online (with a basic `curl` request), if yes they will be printed.

  Actually, `generateHosts.sh` use both sources whereas `generateHosts2.sh` only use the second one which is sufficient. That's why `mug` only use `generateHosts2.sh` 

**generateTokens.sh :**

- create the list(s) of token based on an *alphabet*, a *tokenLength* (positive integer) and a *scatterRate *(positive integer) (which is optionnal)

  - a *token* is a sequence of *tokenLength* characters. The characters used come from *alphabet*.

  - The goal of generateToken is to generate every possible token according to the parameters.

  - This is done using a basic recursive function. Which, in natural language and simplified, look like :

    ```natural
    ALPHABET is globally defined
    function generateToken(todoLength : INT, currentString : STRING)
    	for each character in ALPHABET:
    		nextString = currentString + character
    		if todoLength > 1 :
    			generateToken(todoLength - 1, nextString)
    		else: # means that todoLength = 1 therefore nextString a "complete" token
    			print nextString to sdtout or write nextString to a file # depends on situtation
    ```

  - As you may have remarked, this method may create monstrous file of a lot of GB, because the number of token created is equal to :
    $(\text{alphabet size})^{\text{tokenLength}}$
    For instance, if `alphabet='abcdefghijklmnopqrstuvwxyz'` and `tokenLength=5` the number of token will be equal to $26^5$ or $11881376$, given the fact that each characters takes 1 bytes in ASCII and that there're 5 characters in each token, the space needed will be equal :
    $(\text{space taken by a token}) \times (\text{number of token}) = (\text{tokenLength + 1 bytes}) \times 11881376 = 6 \times 11881376 \ \text{bytes} = 59 406 880 \ \text{bytes} \approx 59 \times 10^6 \ \text{bytes} = 59 \ \text{Mb}$

  - To solve the problem of huge file, a *scatterRate* is used, the mechanism used scatter the file by the first character of the *token*. 

    - For instance, if the script is launched using : `alphabet=abc ; tokenLength=2 ; scatterRate = 1` it will create three file :
      - `a.txt` : containing all tokens beginning by 'a'
      - `b.txt` : containing all token beginning by 'b'
      - ....
    - Moreover, the following configuration : `alphabet=abc ; tokenLength=3 ; scatterRate = 2` will give : 
      - folder ` a` containing all file which contained token beginning by 'a'
        - `a.txt` containing all tokens beginning by 'aa' (since it's in the folder `a`)
        - `b.txt` containing all tokens beginning by 'ab' (since it's in the folder `a`)
        - ...
      - folder `b` containing all file which contained token beginning by 'b'
        - ...

  - Unfortunately, using a *scatterRate* doesn't let us use less space (which is impossible if we want every *token* to be written somewhere in a file) but it let us create smaller file, which are easier to manipulate.

  - In this way, file have a maximum size of :
    $(\text{alphabetLength})^{\text{tokenLength}} \times (\text{tokenLength} + 1) \times \frac{1}{(\text{alphabetLength})^{\text{scatterRate}}} = \frac{(\text{alphabetLength})^{\text{tokenLength}}}{(\text{alphabetLength})^{\text{scatterRate}}} \times (\text{tokenLength} + 1)$

    Thus, it gives :

    $(\text{alphabetLength})^{\text{tokenLength - scatterRate}} \times (\text{tokenLength} + 1) \ \text{bytes}$

    With this formula, we clearly see that *scatterRate* must be inferior to *tokenLength*, moreover in the case where *scatterRate* = *tokenLength*, each file will only hold 1 token (since $x^0 = 1$), which is useless. Therefore, in the script, *scatterRate* must be strictly inferior to *tokenLength*.

We can also specify a *outputDirectory* where the file(s) containing the tokens will be stored.

**Use of generateTokens.sh and generateHosts.sh :** 

- `generateHosts.sh` is used only one time since same hosts are used for all tokens.

- `generateTokens.sh` is used multiple times in a specific range. The range is by default 1 - 4, but it is recommended to the user to set it with `-m` and `-M`, respectively for the lower limit and the upper limit of the range.

  - Since *scatterRate* must be strictly inferior to *tokenLength* and *tokenLength* will vary, when `generateTokens.sh` is launched for a specific *tokenLength* called *i*, the actual *scatterRate* given is :
    $
    \text{specificScatterRate} = \min(i - 1, \text{scatterRate})
    $

- 

## 2. `meg`'s launching

- Once hosts and paths/tokens have been created, when can launch meg using this file.

- In one hand, this step can be the easiest one because we just have to launch a command because we've now *hosts* and *tokens* (called *paths* in `meg`'s vocabulary)

- But on the other hand, if *scatterRate* has been used, we need to launch `meg` for each file created, which is more difficult. This is done using a recursive function, which is in natural language : 

  ```natural
  ALPHABET is globally defined
  HOST represents the hosts file, which path is globally defined
  function launchMegRecursive(todoScatterRate : INT)
  	if todoScatterRate = 0:
  		for character in ALPHABET:
  			# character.txt represent the file containing the token 
  			launch meg on HOST character.txt 
  	else : # todoScatterRate >= 1
  		for character in ALPHABET:
  			# character is the name of a folder in the current working directory
  			cd character 
  			launchmegRecursive(todoScatterRate - 1)
  			cd ..
  ```

- This function is launched for each length in the range given by `-m` and `-M`, if *scatterRate* is used.

## 3. After `meg`

- When meg has finished to run, mug filters its output (which has already been filtered by `meg` itself when we used `-s` to save only requests with a ~300 HTTP code). The output of meg is a set of folders, each representing a host plus index (a sum up of the work did by meg). To retrieve the valuable data (in our case), `afterMeg.sh` is used. Here is its functioning : 

- For each *host*, out of each requests made to this *host*`afterMeg.sh` retrieves the HTTP code, the redirect url and the shortened url.

- Then it process them to delete the 'false redirect codes' which are the HTTP code showing up when the redirect url is a bad one, most of the time these redirect urls point to the home or index webpages of the specific host, because the shortened url doesn't exists.

- As `meg`, `afterMeg.sh` will create a folder (called by default `mugOut` but it can be changed) containing others folders, each representing a *host*. For each *host*, all the ~300 HTTP code requests will be stored in `index.txt` and the unique requests (which are the requests of `index.txt` without the 'false redirect requests') will be stored in `uniqueIndex.txt`.

  - A line in `index.txt` looks like : `httpCode | shortenedUrl | unshortenedUrl`

  - A line in `uniqueIndex.txt` looks like : `shortenedUrl | unshortenedUrl` since in theory, the HTTP code should be same for every 'good redirect url'.

- Finally, `afterMeg.sh` asks the user if he/she wants a file called `finalOutput.txt`, which concatenate every `uniqueIndex.txt` (this job is done using `uniteUnique.sh`). `finalOutput.txt` can also be sorted out, in order to regroup result by domain (and path of the url) and to remove duplicates. 

  - In `finalOutput.txt`, each line simply contains a `unshortenedUrl` , the original `shortenedUrl` doesn't matter a lot. But the code could be manually changed. In the last loop of `uniteUnique.sh`, simply replace : 

    `grep -i . "$folder/uniqueIndex.txt" | cut -d "|" -f 2 | cut -d " " -f 2` 

    by : `grep -i . "$folder/uniqueIndex.txt"` 
