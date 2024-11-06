# Mug ☕
`mug` is a brute-force tool working on a set of *hosts* of the web, for which `https://host/token` give a ~300 HTTP code (=redirect), `token` is a string automatically created from a given *alphabet* and a given *length*. 

For example for `alphabet=abcd` and `length=3`, the tokens created (and tested) are :
aaa, aab, ..., aba, abb, ..., ddd 
In this case, 4^3 (=64) tokens would be created 

`mug` is focused on *url-shortener*, since most of url-shortener use random token and that the redirect url look like : `https://host/token`

Why "mug" ? Because mug is centered on [meg](https://github.com/tomnomnom/meg) of [@tomnomnom](https://github.com/tomnomnom).

In order to understand the goal of `mug`, it is recommended to read [meg's README](https://github.com/tomnomnom/meg)

- Because `mug` use `meg` (with a default delay of 10 seconds), there will be **minimum 10s** between two requests on the **same host**, therefore `mug` can't be considered as a DDOS tool (or it will be a very useless one).

## Installation
- Simply do a basic git clone : `git clone https://github.com/nathanoell/mug.git`

## Use
- After the repo is cloned do : `cd mug`
- Give execution rigth to .sh script : `chmod +x mug.sh`
- And launch the main script : `./mug.sh [OPTIONS]`
  - Example : 
    - `./mug.sh -a abcdefghijklmnopqrstuvwxyz1234567890 -s 3 -m 1 -M 5` 
    - or simpler : `./mug.sh -m 1 -M5` (default alphabet is "abcdefghijklmnopqrstuvwxyzABDCEFGHIJKLMNOPQRSTUVWXYZ1234567890")



## Tips
- **Be aware that `mug` is using a lot of space**, before launching be always sure that you have enough space the alphabet's size and hosts numbers on which you want to launch `mug`

    - The maximum space used is :

    - $$
        (\sum^{\text{M}}_{i=\text{m}} \text{(alphabet size)}^i)\times \text{(number of hosts)} \text{ ko} \times (\sim 500)
        $$

        

        - The huge sum represents the creation of token file. $M$ is the *tokenMaxLength* and $m$ the *tokenMinLength*, $M$ will often be 6 and $m$ 1 or 2.
        - The product is here because every token is requested for every hosts and the request is stored.
        - Fortunately, `meg` let us use HEAD request which use around 1 ko each (if GET requests were used, the size used could be multiplied by a important factor)
        - 10G of free seems good of the $M$ (which is *tokenMaxLength*) doesn't go beyond 6 - 7. 

- **Be aware that `mug` is taking a lot of time to run** (count it in days, if not weeks). If you want to have an idea of the current results who can run `./afterMeg.sh [meg out path] -o 'mugPartialOutput'` to get it (P.S : it's actually the last line of `mug.sh`)

    - The order of time taken is (as for space) :
        $$
        (\sum^{\text{M}}_{i=\text{m}} \text{(alphabet size)}^i)\times (\text{(number of hosts)} + 1)
        $$

    - See `doc/Functioning.md` for more insights on what is going on and what takes time.

    - Since `afterMeg.sh` only reads `meg`'s output, it won't bother its work.

- *token* files are very very slow to be created, so if mug is stopped and launched again, it will use the same token file.

    - Please be aware that even if the token is only partially complete, it will be used. Therefore in order to use `mug` properly and to save time, if it has been stopped accidentally, you can remove the last `pathsN` folder or `pathsN.txt` file and re-launch `mug`.

- If you've changed *alphabet* but you want to keep the same host list, do `cp meg/hosts.txt hosts.txt` then launch `mug [OPTIONS] -H hosts.txt`, using `-H` will save time by not creating again hosts.txt. (When `mug` is launched, it runs `generateHosts2.txt` that pings every host in the file to see if they're still up but it takes time)
## Functioning
See `doc/Functioning.md` for a detailed explanation.

## Possible Improvements

Here are some leads one can follow to improve the tool, sadly I don't have the time to implement them right now.

- Reduce token creation's time 
  - By only running the function using *tokenMaxLength* and, during the process of the function, use current string to create the others token files.
  - Quite vague for the moment
- May be increase the concurrency of `meg` using `--concurrency`  from 20 (set by default) to 30 or higher 
  - I didn't test it yet, in one hand it can be useful and speed up `mug` but it the other hand it could possibly make one's IP banned.

## Thanks
- A huge thanks to [@tomnomnom](https://github.com/tomnomnom) for his incredible tool [meg](https://github.com/tomnomnom/meg)
- and to God <3
- and [@PeterDaveHello](https://github.com/PeterDaveHello) for the list of online url shortener.