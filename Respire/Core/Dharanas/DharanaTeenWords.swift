//
//  DharanaTeenWords.swift
//  Respire
//
//  The gates for teens, in plain words about real days: school, phones, friends,
//  exams, and nights. Same practices, without the jargon.
//

import Foundation

extension Dharana {
    static let teenVersions: [Int: Wording] = [
        // I · Breath
        1: .init("The In-Between Breath",
            "Notice the tiny pause between breathing in and breathing out, right before you hit send."),
        3: .init("The Long Exhale",
            "Make each out-breath a little longer than the in-breath. It tells your body you're safe, even mid-exam."),
        4: .init("Tingling Palms",
            "Before you pick up your phone or a pen, hold your hands still and feel them tingle."),
        5: .init("Back to the Heart",
            "Every time a message or notification comes in, drop your attention into the middle of your chest."),
        6: .init("Breathing Up the Spine",
            "Sitting still at your desk, imagine the breath moving up and down your spine."),
        7: .init("Three Empty Breaths",
            "Take three breaths without planning, scrolling, or replaying anything."),
        8: .init("One Breath Between Apps",
            "Take one full, quiet breath every time you switch apps or tabs."),
        9: .init("The Belly Anchor",
            "When your feed is moving fast, keep part of your attention resting in your belly."),
        10: .init("Breathing in Light",
            "Imagine breathing light in through your forehead, washing away tired eyes and a full head."),
        11: .init("Breathing Out the Day",
            "Breathe out as if through your whole skin, letting the rush of the day leave with it."),
        12: .init("The Thread Underneath",
            "Notice your breath carrying on underneath everything: class, chats, games, all of it."),

        // II · The senses
        13: .init("Soft Eyes",
            "Let your eyes go soft on the screen until it's just shapes and light."),
        14: .init("Just Sound",
            "Listen to the hum of the room, a fan, or traffic, as sound only, without naming it."),
        15: .init("Just Touch",
            "Hold your phone, a pen, or your sleeve, and feel it without naming it."),
        16: .init("Screen Off, Eyes Closed",
            "After looking at a bright screen, close your eyes and rest in the dark behind them."),
        18: .init("Just the Voice",
            "Listen to a voice, a podcast or a teacher, for its tone and rhythm, not its words."),
        19: .init("Wide Vision",
            "While looking at a screen, let your attention spread out to the far left and right."),
        20: .init("What Does the Room Smell Like?",
            "Notice the smell of the air right now. It's real, and it's here."),
        21: .init("One Slow Sip",
            "Put your phone down and drink some water slowly, really tasting it."),
        22: .init("Who's Looking?",
            "Turn your attention around, toward the one who's doing the looking."),

        // III · Open space
        26: .init("The Blank Search Bar",
            "Open a search bar and don't type anything. Just rest in not needing anything."),
        27: .init("Clearing Your Head",
            "Imagine closing every open tab in your mind, one by one, until it's clear."),
        31: .init("Nobody Can Predict This",
            "Notice that no app, teacher, or friend can predict exactly what this moment will be."),
        32: .init("After the Ping",
            "When a notification sound ends, follow it all the way into silence."),
        33: .init("It's Just Light",
            "Look at your screen and see it as what it is: light coming through glass."),
        34: .init("One Minute of Nothing",
            "Spend sixty seconds not watching, posting, or planning anything."),

        // IV · Feelings
        37: .init("The Urge to Check",
            "Feel the pull in your body when you reach for your phone, and pause before you do."),
        39: .init("Drama as Energy",
            "When something online makes you angry, feel it as heat in your body before you react or reply."),
        40: .init("Keep the Joy a Moment",
            "When something makes you happy, enjoy it for a breath before you share it."),
        41: .init("Good Without the Likes",
            "Feel good about something you did, without needing anyone to like it."),
        43: .init("A Steady Heart",
            "Scroll through the news and keep your heart steady, like a still lake."),
        45: .init("Stay With the Question",
            "Hold a question in your mind for two minutes before you look it up. Enjoy wondering."),
        46: .init("You're Not Your Profile",
            "Notice the version of you online is something you show, not who you are."),
        48: .init("It's Okay Not to Know",
            "Let yourself not know an answer for a while, without rushing to look it up."),

        // V · Sound
        51: .init("The Hum as an Anchor",
            "Use the steady hum of a fan or a laptop to settle into quiet inside."),
        57: .init("The Gaps Between Words",
            "When someone is talking, listen for the tiny silences between their words."),

        // VI · The body
        65: .init("Find Your Pulse",
            "Feel your heartbeat in your fingertips or chest, no watch, no app."),
        69: .init("Unknot Your Shoulders",
            "Breathe into your neck and shoulders, stiff from desks and screens, and let them drop."),

        // VIII · Sleep and switching
        85: .init("Phone Down Before Sleep",
            "Put your phone away half an hour before bed and feel your mind slowly dim."),
        87: .init("Before You Check Your Phone",
            "When you wake up, notice the first moment of being awake, before you look at anything."),
        88: .init("Like a Dream",
            "Watch videos and feeds as if they were dreams passing by."),
        91: .init("Know Why You're Opening It",
            "Before you open an app, say to yourself why you're opening it."),
        92: .init("Closing Up",
            "When you close an app, feel your attention come back into your body."),
        93: .init("Midnight Quiet",
            "Late at night, feel how quiet the world is underneath all the noise of the day."),
    ]
}

extension DharanaSection {
    /// Section names for teens: plain, and not trying too hard.
    static let teenWords: [String: (title: String, subtitle: String)] = [
        "I": ("Breath & Pace", "Slowing down to the speed of your breath"),
        "II": ("Your Senses", "Seeing, hearing, and feeling what's actually here"),
        "III": ("Headspace", "The quiet underneath your thoughts"),
        "IV": ("Feelings & Phones", "Meeting urges, drama, and stress as feelings in the body"),
        "V": ("Sound", "Sound and vibration as a way into quiet"),
        "VI": ("Your Body", "Coming back to weight, bones, breath, and skin"),
        "VIII": ("Sleep & Switching", "Waking up, winding down, and moving between things"),
    ]
}
