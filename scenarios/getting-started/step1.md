# Garden.io 🪴

## Getting started ✨

First; move into our quickstart-example codebase with: `cd quickstart-example`{{exec}}

Garden ships with an interactive command center we call the dev console.

To start the dev console, run:  `garden dev`{{exec}} 🔨

The first time you run garden dev, Garden will initialize then await further instructions inside a REPL. From inside the REPL you can command Garden to *build*, *test*, and *deploy* your project. <br>

After running garden dev, you're ready to deploy your project with the following command 🚀

```
deploy --forward
```{{exec}}

If the above command fails for any reason; simply wait for it to finish and run it again `deploy --forward`{{exec}}.

After the deployment is done; you can access the `voting` application through this [URL]({{TRAFFIC_HOST1_30000}}).
