### Refinement for blog-research-driven-development.md

**ADD A SECTION: "The Human's Role — Asking the Right Questions"**

Wayne's core contribution isn't writing code or docs — it's shaping the work stream through decisions and questions:

1. **Vision calls:** Declared Dwarf Fortress as reference model. Chose research-first over build-first.
2. **Architecture questions:** "Can we separate the engine so Bart and Smithers don't collide?" → led to the UI/parser refactor
3. **Design boundary questions:** "What happens when objects cross level boundaries?" → led to the destruction-puzzle directive
4. **Process questions:** "Do we need level .lua files?" → led to Bart designing the level data architecture
5. **Organization questions:** "Why is QA in its own silo?" → dissolved QA, embedded testers in departments
6. **Training directives:** "Bob needs to learn from research before inventing puzzles" → research-first pipeline
7. **Quality gates:** "Nelson must give puzzle feedback to Bob" → created the learning loop

The human doesn't write the code. The human asks the questions that shape what the code becomes. Every major architectural decision in this project traces back to a question Wayne asked, not a line of code he wrote.

This is the blog's thesis: in AI-assisted development, the human's highest-leverage activity is asking the right questions at the right time.
