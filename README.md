# LegionIO

LegionIO is a framework for automating and connecting things. You can see all the docs inside confluence  
https://legionio.atlassian.net/wiki/spaces/LEGION/overview
https://legionio.atlassian.net/wiki/spaces/LEX/pages/7864551/Extensions
*Soon to be migrated to GitHub Wiki*

### What does it do?
LegionIO is an async job engine designed for scheduling tasks and creating relationships between things that wouldn't 
otherwise be connected. Relationships do not have to be a single path. Both of these would work
* `foo → bar → cat → dog`
```
a → b → c
    b → e → z
        e → g
```
In the second scenario, when a runs, it causes b to run which then causes both c and e to run in parallel

It supports both conditions and transformation. The idea of a transformation is you can't connect two indepedent services 
and expect them to know how to talk to each other. 

### Running
Run `gem install legionio` to install legion. If you want to use database features, you will need to 
run `gem install legion-data` also. 

After installing gem you can use the commands `legionio` to start legion, `legion` to access things
and `lex_gen` to generate a new legion extension

### Example Legion Extensions(LEX)
* [lex-http](https://github.com/LegionIO/lex-http/src/master/) - Gives legion the ability to make http requests, [docs](https://legionio.atlassian.net/wiki/spaces/LEX/pages/12910593/Lex+Http)
* [lex-influxdb](https://github.com/LegionIO/lex-influxdb/src/master/) - Write, read, and manage influxdb nodes, [docs](https://legionio.atlassian.net/wiki/spaces/LEX/pages/614891774/Lex+Influxdb)
* [lex-log](https://github.com/LegionIO/lex-log/src/master/) - Send log items to either stdout or a file with lex-log, [docs](https://legionio.atlassian.net/wiki/spaces/LEX/pages/614858995/Lex+Log)
* [lex-memcache](https://github.com/LegionIO/lex-memcached/src/master/) - run memcached commands like set, add, append, delete, flush, reset_stats against memcached servers, [docs](https://legionio.atlassian.net/wiki/spaces/LEX/pages/614858753/Lex+Memcached)
* [lex-pihole](https://github.com/LegionIO/lex-pihole/src/master/) - Allows Legion to interact with [Pi-Hole](https://pi-hole.net/). Can do things like get status, add/remove domains from the list, etc 
* [lex-ping](https://github.com/LegionIO/lex-ping/src/master/) - You can ping things?, [docs](https://legionio.atlassian.net/wiki/spaces/LEX/pages/631373895/Lex+Ping)
* [lex-pushover](https://github.com/LegionIO/lex-pushover/src/master/) - Connects Legion to [Pushover](https://pushover.net/), [docs]()
* [lex-redis](https://github.com/LegionIO/lex-redis/src/master/) - similiar to lex-memcached but for redis
* [lex-sleepiq](https://github.com/LegionIO/lex-sleepiq/src/master/) - Control your SleepIQ bed with Legion!
* [lex-ssh](https://github.com/LegionIO/lex-ssh/src/master/) - Send commands to a server via SSH in an async fashion, [docs](https://legionio.atlassian.net/wiki/spaces/LEX/pages/614891551/Lex+SSH)

Bitbucket repos for extensions that are active or being worked on
[lex list](https://github.com/LegionIO/workspace/projects/LEX)
A nice list in the wiki to view all the extensions, their docs and status
[Legion Extensions](https://github.com/topics/legionio?l=ruby)

### Scheduling Tasks
1) Ensure you have the Legion::Data gem installed and configured  
2) Make sure to have `lex-scheduler` extension installed so that it generates the schedules table in the database  
3) From there you can add a function to be run at a given cron syntax or interval  
4) Setting the interval column will make the job run X seconds after the last time it is completed and will ignore the cron colum  
5) Setting the cron column will ensure the job runs at the given times regardless of when it was run last, only works if interval is null  
6) Cron supports both `*/5 * * * *` style and verbose like `every minute` and `every day at noon`

### Creating Relationships
*To be populated*

### Conditions
You can create complex conditional statements to ensure that when a triggers b, b only runs if certain conditions 
are met. Example conditional statement
```json
{
  "all": [{
    "fact": "pet.type",
	"value": "dog",
	"operator": "equal"
  },{
	"fact":"pet.hungry",
	"operator":"is_true"
  }]
}

```
You can nest conditions in an unlimited fashion to create and/or scenarios to meet your needs
```json
{
  "all": [
	"any":[
	  {"fact":"pet.type", "value":"dog","operator":"equal"},
	  {"fact":"pet.type", "value":"cat","operator":"equal"}
	],
	{
	  "fact": "pet.hungry",
	  "operator": "is_true"
	},{
	  "fact":"pet.overweight",
	  "operator":"is_false"
	}]
}
```
*Conditions are supported by the `lex-conditioner` extension and are not required to be run inside the legion framework*  
You can read the docs with more examples in the [wiki](https://legionio.atlassian.net/wiki/spaces/LEX/pages/614957181/Lex+Conditioner)


### Transformations
Transformations are a critical piece of interconnecting two independent items. Without it, service B doesn't know what
to do with the result from service A
`lex-conditioner` uses a combination of the [tilt](https://rubygems.org/gems/tilt) gem and erb style syntax.
##### Examples
Creating a new pagerduty incident 
```json
{"message":"New PagerDuty incident assigned to <%= assignee %> with a priority of <%= severity %>","from":"PagerDuty"}
```
Example transformation to make the `lex-log` extension output a message
```json
{"message":"transform2","level":"fatal"}
```
You can also call Legion services to get the data you need, example sending a pushover message
```json
{"message":"This is my pushover body", "title": "this is my title", "token":"<%= Legion::Settings['lex']['pushover']['token'] %>" }
```
Or if you wanted to make a real time call via `Legion::Crypt` to get a [Hashicorp Vault](https://www.vaultproject.io/) value
```json
{"message":"this is another body", "title":"vault token example", "token":"<%= Legion::Crypt.read('pushover/token') %> "}
```
*Transformations are supported by the `lex-transformation` extension and are not "technically" required to be run inside the legion framework*  
You can read the docs with more examples in the [wiki](https://legionio.atlassian.net/wiki/spaces/LEX/pages/612270222/Lex+Transformer)

## FAQ
### Does it scale?
Yes. Actually quite well. The framework uses RabbitMQ to ensure jobs are scheduled and run in a FIFO order. As you add
more works, it just subscribes to the queues the workers can support and does more work. It is really geared towards a
docker/K8 type of environment however it can be run locally, on a VM, etc.   

As of right now, it has been tested to around 100 workers running in docker without any performance issues. You will 
likely see performance issues on the DB or RabbitMQ side before Legion has issues. 

Another benefit is that you can run multiple LEXs in one worker or you could have dedicated workers that only run a single LEX.  
In example if you have to make a ton of ssh connections via `lex-ssh`, maybe you want to run 10 pods with no other extensions in them
but then run a pod with `lex-pagerduty`, `lex-log` and `lex-http` to send out notifications after each ssh task is completed

### High Availability
Because you can run this thing with multiple processes and it will distribute the work, it is naturally HA oriented. 
if a worker goes down for some reason, another one should pick it up(assuming another work has that LEX enabled). There
are no hidden features, pay walls, etc to get HA. Just run more instances of LegionIO

### Price and License
LegionIO is completely free. It was build using free time. There are no features held back, no private repos.
Everything is under an MIT license to keep it as open as possible. With that, the devs can't always help with support,
well because it's free.

### Who is it geared for?
Anyone? Everyone? It could be used in a homelab to automate updating VMs. It could be used by someone to take ESPHome
sensor data and pipe it to influxdb. At least that is what @Esity does. It could also be used by a company or enterprise looking
to replace other tools.

### But it is written in ruby
Yep. 

### Similiar projects
There are multiple projects that are similiar. Some things like IFTTT are great(but is it?) but then again, cost money.  
* [Node-Red](https://nodered.org/) - No HA but has some good features and a great drag and drop interface  
* [n8n.io](https://n8n.io/) - Working on HA but [not there yet](https://github.com/n8n-io/n8n/pull/1294)  
* [StackStorm](https://stackstorm.com/) - Written in Python, has potential but I feel they are removing features to convince you to pay for it  
* [Jenkins](https://www.jenkins.io/) - It's jenkins. I don't need to say anything else  
* [Huginn]() - Another IFTTT style app written in ruby. Not sure on this one but it doesn't have HA from what I can tell [github issue](https://github.com/huginn/huginn/issues/2198)  

### Other fun facts
* Supports Hashicorp vault for storing secrets/settings/etc  
* Can enable global message encryption so that all messages going through RMQ are encrypted with aes-256-cbc  
* Each worker generates a private/public key that can be used for internode communication, it also will generate a cluster secret  
for all nodes to have so they can share data accross the entire cluster. The cluster secret by default is stored only in memory and
and is generated when the first worker starts
