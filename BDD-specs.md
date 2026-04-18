# Media Harness
A kubectl-like tool for media creation
Idea

I want to create a SW project which is quite complex and ambitious. The idfea is to support a number of "project types/templates" and I can give you the 3 I have in       mind already, and to supportit in a testable, confgiurable way in big YAML files.                                                                                       

Since I work for Google, we’re showcasing the following models:
Gemini for text and media understanding (for feedback loop - was this media generated good or not)
Lyria for music and songs
Nanobanana for image creation AND EDITING (this is important)
Veo for video creation
Chirp or Gemini TTS for audio (TTS): https://blog.google/innovation-and-ai/models-and-research/gemini-models/gemini-3-1-flash-tts/ 
AVTool and other linux tools to compose deterministically videos (eg juxtapose audio tracks, msuic, silent video into a 8sec homogenous track, blah blah).
Three examples:
Text/image story. Create a story in N=5 chapters. Every chapter has a substory and an image related to it. The story might have a character in input (eg my son Alessandro) and a folder with a few pics of Alessandro to nject in th images with character consistency.
Video project. A video of 32sec comprised of 4 subchapters of 8sec each. Each chapter will have a video (Veo), maybe a music (Lyria) or maybe a narrator story (Chirp).
Comic strip. A story made of N rows , each row consisting of 1-5 comic parts with characters interacting with bubbles.

As you note, in all of these projects we have a global output artifact which consist of a number of “parts” (story chapters, …)

TEchnology:
Use all Google Models, used via gcloud/vertex or API KEY. We start with just an API KEY but we might have to got Vertex to do more complex things 
Use VErtex Media MCP by Hussain  https://github.com/GoogleCloudPlatform/vertex-ai-creative-studio/tree/main/experiments/mcp-genmedia 
I’ve created a conveniente SKILL to install it in https://github.com/palladius/gemini-cli-custom-commands/tree/main/skills/genmedia-setup 
AVtool is convenientely in Hussain 

## The overall architecture

### The Class / Template
I foresee a Class/Object metaphor where the Class is a Template (a 4-chapter Video, A Comic book, a Kids story). 
It has the shape of a YAML but might be powered by prompts in the shape of a skill (under skilLs/my_skill_name//SKILL.md, Anthropic SPECS: https://agentskills.io/specification ), like comic_strip.yaml.
Each Class can be tested statically for errors.
The YAML can be tested by a generic parser. The yaml will use kubernetes style entities and each entity can be a custom class (eg ComicBookStory which has an array of ComicBookChapter, which in turn contains a  ComicBookChapterText and ComicBookImage and so on). Each object has an expected file type (video, image, Text, MD, sound, ..) and some metadata, depending on the type (language for text, duration for video, model_voice for audio, ..).
We want to be as DRY as possible, so we’ll equip most classes with smart defaults (eg default Gemini model to generate a video). This is something we’ll maintain manually and we can figure out in the future.
These classes will be checked in code to encourage more to be created and they will be unit tested.

#### The Object
In some way, the user can invoke the script with a generic prompt or better with a YAML. So we can create some nice yaml and edit them away :) It could be something like:

```
# ale_story.yaml

# This is a story for my son Alessandro who likes pokemon
ClassType:KidsStory
Prompt: |
    write a nice story for my son Alessandro
```

Then I will call `kubectl apply ale_story.yaml –-prompt “make it in Southafrican safari”`. 
Note we can always add a –prompt for last minute editing.
This will likely be created under out/YYYYMMDD_HHMM_whatever_you_want/ . 
This folder will need to have a determnisic content, based on the class 
Note: you decide if the class contains the filename, or filename template, like chapter_XXX.txt or whatever. The important is that it can be deterministically tested without the use of an LLM!
Any script can find the status of the creation in <200ms (also called Larry-Sergey latency). I can do “kubecrtl status FOLDERNAME” and see the beautiful emojis showing green 🟢 chapter1.txt and 🩶 chapter2.txt and so on.


### Common Classes
We can probably create some nice reusable components, like “Character”. A character could be a person with a `name`, a `personality` and a `visual_look` which is important in story vs image generation. It could also have a character_consistency_folder: 
Note: I have a skill for character consistency already so we can reuse it. Ask me later :) 

Or also “Story” could have some common stuff.

Ideally all these concepts should be:
Packaged into skills for LLM consumption and context optimization…
… but also statically testable in sub-second.
Not sure how to manage both, we could FORCE/REQUIRE every skill to implement some common <script/COMMON_NAME.rb> to ensure that everything gets called in the same way (the software will define the specs, and test against those specs).
A huge `just test` should test both the software itself and also the classes

## Feedback loop

### User feedback

The user should be ALWAYS able to give feedback or some creation, like

$ kubectl feedback FOLDER/chapter1.md –prompt “This story is lame. Make it more complex”
$ kubectl feedback FOLDER/chatper1_image.png –prompt “My son has wrong eye color, pls check” # Assume his eye colors are written somewhere.

An LLM will piggyback into the creation and take action. 
FUNCTIONAL REQUIREMENT. Since LLM creations are expensive, we do NOT destroy anything, rather archive into a .trash/ intelligently.
The expected behaviour is that the object is conceptually “deleted” (archived) by the harness/engine, and all its dependant are marked unready/archived too in cascade. Eg, if a story has two sound “prnounce me in EN and in IT” and one image “Alessandro in this chapter” dependencies, these 3 needs to be archived and re-calculated. All of this needs to be logged, for the final token cost/time calculation.


### System automated evals

The Class will have by default an overrideable array of evals. An eval is a couple (input prompt, expected output) and an optional model (dflt: gemini 3 flash)


## Final Software shape aspect.

The most revolutionary aspect of this software is that LLMs take time to generate stuff, exp media. Text, images… take time and Video even more. Some things take more, some things take less. it needs to be able to work out dependencies and call in parallel (async) those things.

This will be done in a public git repo. Let’s ensure keys stay private in a global GITROOT/.env . Use <git-privatize> from GH palladuis/sakura to manage the .env. Lets git ignore out/ of course, we will have some showcase demo stuff to hold the best of the best,. Pending GH filesize limits (100MB iirc).

## Non-function aspects

We need to be able to track/log how much time each call takes to see how long each part takes. Note some of these times are in parallel, so TS begin and TS end seem a good compromise.
We need to be able track inut and out tokens for every call, and also the type of model called so we can in the end draft the cost expenditure.
Backup to GCS. Since media are expensive, having a sync to and from a configurable GCS bucket seems like a nice feature for V2.
When i write kubectl, I mean whatever the tool you are gonna call 🙂 
We should be able to stop/start/resume the arneis at anytime - of course pending actions will still be happening and it might take upto 1min (Veo is usually the slowest) to reach quiescence. I dont expect perfectio here :) 
All the code should be thoroughly TESTED! I like BDD.
As a rubyist, I love DRY and Default over configuration. Let’s choose smart defaults for everything!
Deterministic over LLM. LLMs are expensive. Lets always get to the max mile with deterministic code, and the last ile where this is impossible we’re leveraging an LLM - lets not over use them thats what I mean.

A <kubectl stats FOLDER> will give me the output.

## The app

We start with a CLI, I would expect some sort of `kubectl apply` of a certain.
Full of emojis and colorfl
<Justfile> for everything
Gemini and Google stack for everything if possible.
In the future (v2) i want a nice, responsive Node.js App which shows me the progress of my creation, like “story generated, chapter 1,2,4 generated, story 3 in progress, image 1 generated, image 2,4 in progress (note: image 3 CANNOT be in progress since it requires chapter 3).
The CLI should be able to track the status, so when we create a complex object there should be some sort of “watch creation-status” in watch style, but colorful, with arrows for dependencies, and culorful bullets for Done (green), in progress (yellow), not started but ready (white), not ready as deps not required (gray)... it needs to be visually appealing and updating in real time.

## Language
I’d like this arneis to be created in ruby, and use ruby fiber for async.
We can use rubyllm as gem for Gemini and LLM invocation, but you choose, Im not fuzzy.
We can also have a simple web app written in rails to show all the stuff.

## Additional readings

* I've done something similar in the past if you wanna look: ~/git/gemini-cli-demos/demos/mcp-video-creation/ . You can find A LOT of existing materials, videos, stories there. This is basically the "grown up, cubic version" of it :)
    * one example here: ./stories/20250911-1230-CUJ03-rubycon-pitch/video_plan.yaml
* See Hussain MCP Multimedia: https://github.com/GoogleCloudPlatform/vertex-ai-creative-studio/tree/main/experiments/mcp-genmedia and my skill to install it! ~/git/gemini-cli-custom-commands/skills/genmedia-setup/SKILL.md