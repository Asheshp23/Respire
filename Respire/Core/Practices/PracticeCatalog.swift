//
//  PracticeCatalog.swift
//  Respire
//
//  The guided sessions, each with its full spoken script, by persona:
//
//  - Kids     Bumble Bee Breath, Balloon Belly, Sleepy Starfish
//  - Teens    Box Breathing for Stress, Sleep Sanctuary, Before a Test
//  - Adults   Space Before You Speak, Cool the Argument, Boundary Breath
//  - Pranayama (adults and the Wise)   Bhramari, Nadi Shodhana
//  - Wise     Gentle Chair Breath, Evening Gratitude
//
//  Written to be heard, not read: short sentences, plain words, room to breathe.
//  Children and the Wise have no breath holds. Agnisar is left out on purpose; it's
//  forceful abdominal work that shouldn't be taught by voice alone.
//

import Foundation

private func line(_ text: String, _ pause: Double = 2) -> VoiceLine {
    VoiceLine(text: text, pause: pause)
}

extension Practice {
    static let all: [Practice] = kids + teens + adults + pranayama + wise

    // MARK: - Kids

    private static let kids: [Practice] = [
        Practice(
            id: "bumble-bee", title: "Bumble Bee Breath",
            summary: "Breathe in like a flower, hum out like a happy bee.",
            personas: [.kids], category: .calm, inhale: 4, exhale: 6, breaths: 5,
            world: .sakura, focus: .calmAnxiety, hums: true,
            intro: [
                line("Hello, little explorer.", 1.5),
                line("Today we're going to breathe like a happy bumblebee."),
                line("Sit somewhere comfy. Cross your legs, or let your feet rest flat on the floor."),
                line("You can rest your hands in your lap. Or put your fingers gently over your ears, to feel the buzzing even more."),
                line("Close your eyes if that feels nice, or let them go soft and sleepy.", 3),
                line("When we hum, we make a buzzing sound, like a bee resting on a flower. It helps our body feel calm and our heart feel light."),
                line("Let's try it together.", 1.5),
            ],
            cues: [
                BreathCue(inhale: "Breathe in through your nose. Fill your belly like a balloon.", exhale: "Now hum it out, like a bee. Mmmmm."),
                BreathCue(inhale: "Breathe in again, nice and slow.", exhale: "And hummm. Can you feel the buzz in your head?"),
                BreathCue(inhale: "In through your nose.", exhale: "Hum like a sleepy bee."),
            ],
            imagery: [
                ["Each time you hum, imagine your wings changing color. What colors do you see?",
                 "Maybe red, then orange, then a sunny yellow.",
                 "One more buzz. What color are your wings now?"],
                ["Imagine your humming makes tiny golden sparkles float all around you.",
                 "The sparkles drift up, slowly, like bubbles.",
                 "One more buzz, and watch them twinkle."],
                ["Your humming is making a happy little song.",
                 "Is it high or low? Fast or slow?",
                 "One more buzz, and listen to your song."],
            ],
            closing: [
                line("Great job, little bee.", 1.5),
                line("How does your body feel now? Light like a butterfly? Soft like a cloud?", 3),
                line("Wiggle your fingers. Wiggle your toes.", 2.5),
                line("And when you're ready, open your eyes. Anytime you need a little calm, just hum like a bee.", 0),
            ]
        ),
        Practice(
            id: "balloon-belly", title: "Balloon Belly",
            summary: "Blow up a balloon in your tummy, then let it slowly float down.",
            personas: [.kids], category: .calm, inhale: 4, exhale: 5, breaths: 6,
            world: .aurora, focus: .calmAnxiety,
            intro: [
                line("Hi there. Let's play the balloon game.", 1.5),
                line("Lie down, or sit up tall. Put one hand on your tummy."),
                line("Pretend there's a balloon inside your tummy, any color you like.", 2.5),
                line("When you breathe in, the balloon gets bigger. When you breathe out, it gets smaller."),
                line("Ready? Here we go.", 1.5),
            ],
            cues: [
                BreathCue(inhale: "Breathe in, and blow your balloon up big.", exhale: "Breathe out, and let it go down slowly. Ssss."),
                BreathCue(inhale: "In, and watch your hand go up.", exhale: "Out, and watch it go down."),
                BreathCue(inhale: "Big balloon.", exhale: "Little balloon."),
            ],
            imagery: [
                ["Now imagine your balloon floating up into the sky.", "It drifts past the clouds, slowly.", "One more breath, and it floats back down to you."],
                ["Your balloon is full of warm sunshine.", "Every breath out, a little sunshine spreads through your body.", "All the way to your fingers and toes."],
            ],
            closing: [
                line("You did it. Your balloon is resting now.", 2),
                line("Put both hands on your tummy, and notice how calm it feels.", 3),
                line("When you're ready, open your eyes.", 0),
            ]
        ),
        Practice(
            id: "sleepy-starfish", title: "Sleepy Starfish",
            summary: "A bedtime breath. Spread out like a starfish and let each part get sleepy.",
            personas: [.kids], category: .sleep, inhale: 4, exhale: 6, breaths: 7,
            world: .ocean, focus: .windDown,
            intro: [
                line("It's almost time to sleep.", 1.5),
                line("Lie on your back and stretch out your arms and legs, like a starfish on the sand."),
                line("Close your eyes.", 2.5),
                line("We're going to breathe slowly, and let every part of you get sleepy."),
            ],
            cues: [
                BreathCue(inhale: "Breathe in slowly.", exhale: "Breathe out, and let your arms get heavy and sleepy."),
                BreathCue(inhale: "Breathe in.", exhale: "Breathe out, and let your legs get heavy and sleepy."),
                BreathCue(inhale: "Breathe in.", exhale: "Breathe out, and let your tummy go soft."),
                BreathCue(inhale: "Breathe in.", exhale: "Breathe out, and let your face go soft and smooth."),
            ],
            imagery: [
                ["Little waves wash up to your toes, and gently away.", "Up to your toes, and away.", "You're a sleepy starfish, safe and warm."],
            ],
            closing: [
                line("Your whole body is sleepy now.", 3),
                line("Keep breathing slowly, all by yourself.", 3),
                line("Goodnight, little starfish.", 0),
            ]
        ),
    ]

    // MARK: - Teens

    private static let teens: [Practice] = [
        Practice(
            id: "box-stress", title: "Box Breathing for Stress",
            summary: "Four equal sides: in, hold, out, hold. Steady when everything feels like a lot.",
            personas: [.teens, .adults], category: .calm, inhale: 4, hold: 4, exhale: 4, rest: 4, breaths: 10,
            world: .rain, focus: .calmAnxiety,
            intro: [
                line("Hey. Thanks for taking a few minutes for yourself.", 1.5),
                line("Sit however's comfortable. Let your shoulders drop."),
                line("Close your eyes, or rest them on one spot.", 2.5),
                line("We're going to breathe in a box. Four counts in, four counts hold, four counts out, four counts hold."),
                line("When your mind is racing, an even rhythm gives it something steady to hold on to."),
            ],
            cues: [
                BreathCue(inhale: "Breathe in for four.", hold: "Hold for four.", exhale: "Breathe out for four.", rest: "And hold."),
                BreathCue(inhale: "Up one side of the box.", hold: "Across the top.", exhale: "Down the other side.", rest: "Across the bottom."),
            ],
            imagery: [
                ["If a thought pulls you away, that's fine. Just pick the box back up where you are.",
                 "You don't have to fix anything right now. Just breathe the box.",
                 "Notice your body getting a little more settled with each side."],
            ],
            closing: [
                line("Let the box go, and breathe however feels natural.", 3),
                line("Notice how you feel compared with when you started.", 3),
                line("You can come back to this anytime. Before a hard conversation, on the bus, anywhere.", 0),
            ]
        ),
        Practice(
            id: "sleep-sanctuary", title: "Sleep Sanctuary",
            summary: "For a busy mind at bedtime. A long, slow out-breath to switch off.",
            personas: [.teens], category: .sleep, inhale: 4, exhale: 8, breaths: 16,
            world: .desert, focus: .windDown,
            intro: [
                line("Time to let the day go.", 1.5),
                line("Put your phone face down, somewhere out of reach once this is done."),
                line("Lie down and get comfortable. Close your eyes.", 3),
                line("If your mind is busy, that's normal. We're not going to fight it. We're just going to slow down the breath, and let the body lead."),
                line("Breathe in for four, and out for eight. The long out-breath is what tells your body it's safe to rest."),
            ],
            cues: [
                BreathCue(inhale: "Breathe in for four.", exhale: "And out, slowly, for eight."),
                BreathCue(inhale: "In.", exhale: "And all the way out."),
            ],
            imagery: [
                ["Imagine putting each thought in a box by the door. It'll still be there in the morning.",
                 "Let your jaw loosen, and your tongue rest in your mouth.",
                 "Feel the bed holding you up. You don't have to hold yourself."],
            ],
            closing: [
                line("Now let the breath go back to its own rhythm.", 3),
                line("There's nothing else to do tonight.", 3),
                line("Stay here, and let sleep come when it's ready.", 0),
            ]
        ),
        Practice(
            id: "test-prep", title: "Before a Test",
            summary: "Two minutes to steady your nerves and see yourself doing well.",
            personas: [.teens], category: .focus, inhale: 5, exhale: 5, breaths: 12,
            world: .aurora, focus: .focus,
            intro: [
                line("Feeling nervous before a test is normal. It means you care.", 1.5),
                line("Sit up straight, feet flat, hands resting on your legs."),
                line("Close your eyes for a moment.", 2.5),
                line("We'll breathe evenly, in for five and out for five. It's the rhythm athletes use to stay calm under pressure."),
            ],
            cues: [
                BreathCue(inhale: "In for five.", exhale: "Out for five."),
                BreathCue(inhale: "In.", exhale: "Out."),
            ],
            imagery: [
                ["Picture yourself walking into the room, calm and steady.",
                 "You sit down, read the first question, and know where to start.",
                 "If you get stuck, you breathe once like this, and move on to the next one."],
            ],
            closing: [
                line("Take one more slow breath.", 3),
                line("You've prepared. You know more than you think.", 2),
                line("Open your eyes, and go and show what you know.", 0),
            ]
        ),
    ]

    // MARK: - Adults: connection

    private static let adults: [Practice] = [
        Practice(
            id: "partner-peace", title: "Space Before You Speak",
            summary: "Before a hard conversation, find the calm you want to bring to it.",
            personas: [.adults], category: .connection, inhale: 4, exhale: 6, breaths: 14,
            world: .ocean, focus: .calmAnxiety,
            intro: [
                line("Before you talk, let's make a little space.", 1.5),
                line("Sit comfortably, and let your hands rest open."),
                line("Close your eyes.", 2.5),
                line("Think of the person you're about to talk to. Not the problem, just them.", 3),
                line("We'll breathe in for four and out for six, so your body is calm before your words arrive."),
            ],
            cues: [
                BreathCue(inhale: "Breathe in.", exhale: "And out, a little longer."),
                BreathCue(inhale: "In.", exhale: "Out, and soften your shoulders."),
            ],
            imagery: [
                ["Notice what you're feeling, without needing to act on it yet.",
                 "Somewhere under the frustration, there's usually something you care about. See if you can find it.",
                 "Think of one thing you'd like them to understand, and one thing you'd like to understand about them."],
            ],
            closing: [
                line("Let the breath settle.", 3),
                line("You can bring this calm with you. If things heat up, one slow out-breath brings you back.", 3),
                line("When you're ready, open your eyes.", 0),
            ]
        ),
        Practice(
            id: "conflict-cool", title: "Cool the Argument",
            summary: "When a disagreement is heating up, settle the reaction before it takes over.",
            personas: [.adults], category: .connection, inhale: 4, exhale: 7, breaths: 12,
            world: .rain, focus: .calmAnxiety,
            intro: [
                line("It's okay to step away for a few minutes. That's not losing. It's caring for the conversation.", 1.5),
                line("Sit down if you can, and put your feet flat on the floor."),
                line("Close your eyes.", 2.5),
                line("Your heart might be racing. That's your body trying to protect you. We'll help it stand down, with a long, slow out-breath."),
            ],
            cues: [
                BreathCue(inhale: "Breathe in for four.", exhale: "And out for seven, like cooling a hot drink."),
                BreathCue(inhale: "In.", exhale: "Out, long and slow."),
            ],
            imagery: [
                ["Notice where the heat is in your body. Your chest, your jaw, your hands.",
                 "Breathe out toward that place, and let it cool a little.",
                 "You don't have to win this. You just have to be the person you want to be in it."],
            ],
            closing: [
                line("Let the breath return to normal.", 3),
                line("When you go back, try starting with what you heard them say.", 3),
                line("Open your eyes when you're ready.", 0),
            ]
        ),
        Practice(
            id: "boundary-breath", title: "Boundary Breath",
            summary: "Feel your edges and your own ground, so you can say what you need, kindly and clearly.",
            personas: [.adults], category: .connection, inhale: 4, hold: 2, exhale: 6, breaths: 12,
            world: .volcano, focus: .focus,
            intro: [
                line("This one is about your own ground.", 1.5),
                line("Sit up tall, with your feet planted and your spine long."),
                line("Close your eyes.", 2.5),
                line("Breathing in, you'll gather a little strength. Holding, you'll feel it. Breathing out, you'll let go of what isn't yours to carry."),
            ],
            cues: [
                BreathCue(inhale: "Breathe in, and feel yourself grow a little taller.", hold: "Hold, gently.", exhale: "Breathe out, and let go of what isn't yours."),
                BreathCue(inhale: "In, and feel your feet on the ground.", hold: "Hold.", exhale: "Out."),
            ],
            imagery: [
                ["Imagine a soft circle of space around you, about an arm's length wide. It's yours.",
                 "Others can come close, by invitation. You decide.",
                 "Think of one thing you need, and say it to yourself, simply. You're allowed to need it."],
            ],
            closing: [
                line("Let the breath settle into its own rhythm.", 3),
                line("Notice your feet, your spine, your own space around you.", 3),
                line("You can be kind and clear at the same time. Open your eyes when you're ready.", 0),
            ]
        ),
    ]

    // MARK: - Pranayama

    private static let pranayama: [Practice] = [
        Practice(
            id: "bhramari", title: "Bhramari",
            summary: "The humming bee breath. A long, humming out-breath that quiets the mind.",
            personas: [.adults, .wise], category: .pranayama, inhale: 4, exhale: 8, breaths: 10,
            world: .cymatics, focus: .calmAnxiety, hums: true,
            caution: "Press the ears only lightly, never into the canal, and stop if you feel dizzy.",
            intro: [
                line("This is Bhramari, the humming bee breath.", 1.5),
                line("Sit comfortably, with your spine long and your shoulders soft."),
                line("If you like, place your index fingers lightly on the small flap at the front of each ear, and press it gently closed.", 2.5),
                line("Close your eyes, and let your lips rest together, teeth slightly apart."),
                line("Breathe in through the nose. Then breathe out with a low, steady hum, for as long as is comfortable."),
            ],
            cues: [
                BreathCue(inhale: "Breathe in through the nose.", exhale: "And hum, low and steady."),
                BreathCue(inhale: "In.", exhale: "Hum, and feel it in your skull and chest."),
                BreathCue(inhale: "In.", exhale: "Hum."),
            ],
            imagery: [
                ["Let the hum fill your head, like a bell ringing softly.",
                 "Notice where you feel it most. The lips, the forehead, the chest.",
                 "Let the hum get a little quieter each time, until it's almost silent."],
            ],
            closing: [
                line("Let the hum go, and rest your hands in your lap.", 3),
                line("Listen to the quiet the hum has left behind.", 4),
                line("When you're ready, slowly open your eyes.", 0),
            ]
        ),
        Practice(
            id: "nadi-shodhana", title: "Nadi Shodhana",
            summary: "Alternate nostril breathing, to balance and steady the mind.",
            personas: [.adults, .wise], category: .pranayama, inhale: 4, exhale: 6, breaths: 12,
            world: .waterfall, focus: .focus,
            caution: "Skip it if your nose is blocked; breathe evenly through both nostrils instead.",
            intro: [
                line("This is Nadi Shodhana, alternate nostril breathing.", 1.5),
                line("Sit tall, and rest your left hand in your lap."),
                line("Bring your right hand up to your face. Your thumb will close the right nostril, and your ring finger the left.", 2.5),
                line("Close your eyes, and let your breath be quiet and smooth."),
                line("Close the right nostril with your thumb, and breathe out gently through the left. We'll begin from there."),
            ],
            cues: [
                BreathCue(inhale: "Breathe in through the left.", exhale: "Close the left. Open the right, and breathe out."),
                BreathCue(inhale: "Breathe in through the right.", exhale: "Close the right. Open the left, and breathe out."),
            ],
            repeatsCues: true,
            closing: [
                line("Release your hand, and breathe through both nostrils.", 3),
                line("Notice the balance, the evenness, left and right.", 3),
                line("Open your eyes when you're ready.", 0),
            ]
        ),
    ]

    // MARK: - Wise

    private static let wise: [Practice] = [
        Practice(
            id: "gentle-chair", title: "Gentle Chair Breath",
            summary: "Seated and unhurried. A soft, easy breath with nothing to force.",
            personas: [.wise], category: .calm, inhale: 4, exhale: 6, breaths: 14,
            world: .aurora, focus: .calmAnxiety,
            intro: [
                line("Welcome. Let's take a few quiet minutes together.", 2),
                line("Sit in a chair with a back, feet resting flat on the floor."),
                line("Let your hands rest on your thighs, palms down or up, whichever feels better.", 2.5),
                line("Close your eyes, or let your gaze rest gently on the floor."),
                line("There's nothing to strain for. If any breath feels too long, just make it shorter."),
            ],
            cues: [
                BreathCue(inhale: "Breathe in, easily, through the nose.", exhale: "And let it out slowly, as if you're sighing."),
                BreathCue(inhale: "In.", exhale: "And out, nice and slow."),
            ],
            imagery: [
                ["Feel the chair holding you. The floor under your feet.",
                 "Let your shoulders drop, a little more with each breath out.",
                 "Notice one small thing you're glad of today."],
            ],
            closing: [
                line("Let the breath find its own pace again.", 3),
                line("Before you stand, wiggle your fingers and toes, and take your time.", 3),
                line("When you're ready, open your eyes.", 0),
            ]
        ),
        Practice(
            id: "evening-gratitude", title: "Evening Gratitude",
            summary: "A slow evening breath, remembering what was good in the day.",
            personas: [.wise, .adults], category: .sleep, inhale: 4, exhale: 7, breaths: 14,
            world: .sakura, focus: .windDown,
            intro: [
                line("Good evening.", 2),
                line("Sit or lie down, wherever you'll be most comfortable."),
                line("Close your eyes, and let your face soften.", 3),
                line("We'll breathe slowly, and let a few good moments from today come back to us."),
            ],
            cues: [
                BreathCue(inhale: "Breathe in.", exhale: "And breathe out, slowly."),
                BreathCue(inhale: "In.", exhale: "And out."),
            ],
            imagery: [
                ["Think of someone you spoke with today. Picture their face for a moment.",
                 "Remember something you saw that was beautiful, even something small.",
                 "And something your body did for you today. Your hands, your legs, your heart."],
            ],
            closing: [
                line("Let those moments rest with you.", 3),
                line("Breathe however feels natural now.", 3),
                line("Rest well.", 0),
            ]
        ),
    ]
}
