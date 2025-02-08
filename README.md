# LLM Chat

I talk to LLMs daily. Have mostly used ChatGPT's web app so far. However over time some things got like super annoying:

- After hitting enter there's a ~2s+ delay for the submitted user message to actually show up in chat, during that time it's stuck in the new user message input
- Sometimes the user message stays in the new user message input and shows up in chat history at the same time
- On long user message have to scroll all the way up to find the edit button at the beginning of the last user message
- Can't always switch models depending on media types in existing chat history some models become unavailable
- No way to switch between chats easily and quickly (fzf-like)
- Love the idea of projects but the UI is not very intuitive so I couldn't really benefit from it at all
- No scroll up to latest user input like on mobile
- No syntax highlighting for dart lang
- No visiblity into when user and bot message have been created (yes I do read old chats somtimes for reference, I like to keep my mind clear and don't just create new chats all the time)
- Can't customizable fonts (books are printed in serif for a reason)
- Can't customizable keyboard shortcuts

That being said I decided to build my own LLM chat how _I_ like it.

This project doesn't support all the features ChatGPT does and is not meant to.

Not all of my complains are yet fixed in my own version either.


## Usage

| Shortcut | Action |
|----------|---------|
| `⌘ + T` | Open project / chat selector |
| `⌘ + A` | Add project / chat |
| `⌘ + R` | Rename selected project / chat |
| `⌘ + D` | Enter delete mode (Enter to confirm, navigate away to cancel) |
| `↑` `↓` | Navigate in list |
| `←` | Go up |
| `→` | Go down |
| `⌘ + ↵` | Submit chat message |
