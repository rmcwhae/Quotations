//
//  DemoCatalog.swift
//  Quotations
//

import Foundation

enum DemoCatalog {
    struct AuthorSeed: Sendable {
        let name: String
    }

    struct QuotationSeed: Sendable {
        let content: String
        let location: String?
    }

    struct SourceSeed: Sendable {
        let title: String
        let authorName: String
        let publicationYear: Int?
        let format: String
        let quotations: [QuotationSeed]
    }

    static let sources: [SourceSeed] = [
        prideAndPrejudice,
        mobyDick,
        frankenstein,
        janeEyre,
        walden,
        aliceInWonderland,
        greatExpectations,
        theOdyssey,
        dracula,
        huckleberryFinn,
    ]

    static var quotationCount: Int {
        sources.reduce(0) { $0 + $1.quotations.count }
    }

    static var authorNames: [String] {
        Array(Set(sources.map(\.authorName))).sorted()
    }
}

// MARK: - Works

private extension DemoCatalog {
    static let prideAndPrejudice = SourceSeed(
        title: "Pride and Prejudice",
        authorName: "Jane Austen",
        publicationYear: 1813,
        format: SourceFormat.printBook.rawValue,
        quotations: [
            QuotationSeed(
                content: "It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife.",
                location: "Vol. I, Ch. 1"
            ),
            QuotationSeed(
                content: "I could easily forgive his pride, if he had not mortified mine.",
                location: "Vol. I, Ch. 5"
            ),
            QuotationSeed(
                content: "There is a stubbornness about me that never can bear to be frightened at the will of others. My courage always rises at every attempt to intimidate me.",
                location: "Vol. II, Ch. 11"
            ),
            QuotationSeed(
                content: "To be fond of dancing was a certain step towards falling in love.",
                location: "Vol. I, Ch. 3"
            ),
            QuotationSeed(
                content: "Angry people are not always wise.",
                location: "Vol. II, Ch. 13"
            ),
            QuotationSeed(
                content: "I am only resolved to act in that manner, which will, in my own opinion, constitute my happiness, without reference to you, or to any person so wholly unconnected with me.",
                location: "Vol. III, Ch. 14"
            ),
            QuotationSeed(
                content: "What are men to rocks and mountains?",
                location: "Vol. II, Ch. 4"
            ),
            QuotationSeed(
                content: "You must learn some of my philosophy. Think only of the past as its remembrance gives you pleasure.",
                location: "Vol. III, Ch. 16"
            ),
            QuotationSeed(
                content: "For what do we live, but to make sport for our neighbours, and laugh at them in our turn?",
                location: "Vol. III, Ch. 15"
            ),
            QuotationSeed(
                content: "I have been a selfish being all my life, in practice, though not in principle.",
                location: "Vol. III, Ch. 16"
            ),
        ]
    )

    static let mobyDick = SourceSeed(
        title: "Moby-Dick; or, The Whale",
        authorName: "Herman Melville",
        publicationYear: 1851,
        format: SourceFormat.printBook.rawValue,
        quotations: [
            QuotationSeed(content: "Call me Ishmael.", location: "Ch. 1"),
            QuotationSeed(
                content: "It is not down on any map; true places never are.",
                location: "Ch. 12"
            ),
            QuotationSeed(
                content: "I know not all that may be coming, but be it what it will, I'll go to it laughing.",
                location: "Ch. 39"
            ),
            QuotationSeed(
                content: "There is a wisdom that is woe; but there is a woe that is madness.",
                location: "Ch. 96"
            ),
            QuotationSeed(
                content: "Better to sleep with a sober cannibal than a drunken Christian.",
                location: "Ch. 3"
            ),
            QuotationSeed(
                content: "Ahab is for ever Ahab, man. This whole act's immutably decreed.",
                location: "Ch. 134"
            ),
            QuotationSeed(
                content: "As for me, I am tormented with an everlasting itch for things remote.",
                location: "Ch. 1"
            ),
            QuotationSeed(
                content: "Talk not to me of blasphemy, man; I'd strike the sun if it insulted me.",
                location: "Ch. 36"
            ),
            QuotationSeed(
                content: "There is no quality in this world that is not what it is merely by contrast.",
                location: "Ch. 11"
            ),
            QuotationSeed(
                content: "And I only am escaped alone to tell thee.",
                location: "Epilogue"
            ),
        ]
    )

    static let frankenstein = SourceSeed(
        title: "Frankenstein; or, The Modern Prometheus",
        authorName: "Mary Shelley",
        publicationYear: 1818,
        format: SourceFormat.printBook.rawValue,
        quotations: [
            QuotationSeed(
                content: "Nothing is so painful to the human mind as a great and sudden change.",
                location: "Vol. III, Ch. 7"
            ),
            QuotationSeed(
                content: "I ought to be thy Adam, but I am rather the fallen angel.",
                location: "Vol. II, Ch. 2"
            ),
            QuotationSeed(
                content: "Life, although it may only be an accumulation of anguish, is dear to me, and I will defend it.",
                location: "Vol. II, Ch. 2"
            ),
            QuotationSeed(
                content: "Beware; for I am fearless, and therefore powerful.",
                location: "Vol. II, Ch. 9"
            ),
            QuotationSeed(
                content: "If I cannot inspire love, I will cause fear!",
                location: "Vol. II, Ch. 9"
            ),
            QuotationSeed(
                content: "The world was to me a secret which I desired to divine.",
                location: "Vol. I, Ch. 2"
            ),
            QuotationSeed(
                content: "How dangerous is the acquirement of knowledge and how much happier that man is who believes his native town to be the world.",
                location: "Vol. I, Ch. 3"
            ),
            QuotationSeed(
                content: "There is something at work in my soul which I do not understand.",
                location: "Vol. I, Letter 2"
            ),
            QuotationSeed(
                content: "I had desired it with an ardour that far exceeded moderation; but now that I had finished, the beauty of the dream vanished, and breathless horror and disgust filled my heart.",
                location: "Vol. I, Ch. 4"
            ),
            QuotationSeed(
                content: "The companions of our childhood always possess a certain power over our minds which hardly any later friend can obtain.",
                location: "Vol. III, Ch. 2"
            ),
        ]
    )

    static let janeEyre = SourceSeed(
        title: "Jane Eyre",
        authorName: "Charlotte Brontë",
        publicationYear: 1847,
        format: SourceFormat.printBook.rawValue,
        quotations: [
            QuotationSeed(
                content: "I am no bird; and no net ensnares me: I am a free human being with an independent will.",
                location: "Ch. 23"
            ),
            QuotationSeed(
                content: "I would always rather be happy than dignified.",
                location: "Ch. 34"
            ),
            QuotationSeed(
                content: "The soul, fortunately, has an interpreter—often an unconscious, but still a truthful interpreter—in the eye.",
                location: "Ch. 23"
            ),
            QuotationSeed(
                content: "I can live alone, if self-respect, and circumstances require me so to do. I need not sell my soul to buy bliss.",
                location: "Ch. 19"
            ),
            QuotationSeed(
                content: "It is in vain to say human beings ought to be satisfied with tranquillity: they must have action; and they will make it if they cannot find it.",
                location: "Ch. 12"
            ),
            QuotationSeed(
                content: "I am not an angel, and I will not be one till I die: I will be myself.",
                location: "Ch. 24"
            ),
            QuotationSeed(
                content: "Even for me life had its gleams of sunshine.",
                location: "Ch. 26"
            ),
            QuotationSeed(
                content: "I care for myself. The more solitary, the more friendless, the more unsustained I am, the more I will respect myself.",
                location: "Ch. 27"
            ),
            QuotationSeed(
                content: "Life appears to me too short to be spent in nursing animosity or registering wrongs.",
                location: "Ch. 6"
            ),
            QuotationSeed(
                content: "Reader, I married him.",
                location: "Ch. 38"
            ),
        ]
    )

    static let walden = SourceSeed(
        title: "Walden; or, Life in the Woods",
        authorName: "Henry David Thoreau",
        publicationYear: 1854,
        format: SourceFormat.printBook.rawValue,
        quotations: [
            QuotationSeed(
                content: "I went to the woods because I wished to live deliberately, to front only the essential facts of life, and see if I could not learn what it had to teach, and not, when I came to die, discover that I had not lived.",
                location: "Where I Lived, and What I Lived For"
            ),
            QuotationSeed(
                content: "The mass of men lead lives of quiet desperation.",
                location: "Economy"
            ),
            QuotationSeed(
                content: "Rather than love, than money, than fame, give me truth.",
                location: "Conclusion"
            ),
            QuotationSeed(
                content: "If a man does not keep pace with his companions, perhaps it is because he hears a different drummer.",
                location: "Conclusion"
            ),
            QuotationSeed(
                content: "Our life is frittered away by detail. Simplify, simplify.",
                location: "Where I Lived, and What I Lived For"
            ),
            QuotationSeed(
                content: "Heaven is under our feet as well as over our heads.",
                location: "The Pond in Winter"
            ),
            QuotationSeed(
                content: "Books are the treasured wealth of the world and the fit inheritance of generations and nations.",
                location: "Reading"
            ),
            QuotationSeed(
                content: "All good things are wild and free.",
                location: "Walking"
            ),
            QuotationSeed(
                content: "Live in each season as it passes; breathe the air, drink the drink, taste the fruit, and resign yourself to the influence of the earth.",
                location: "Spring"
            ),
            QuotationSeed(
                content: "It is never too late to give up our prejudices.",
                location: "Economy"
            ),
        ]
    )

    static let aliceInWonderland = SourceSeed(
        title: "Alice's Adventures in Wonderland",
        authorName: "Lewis Carroll",
        publicationYear: 1865,
        format: SourceFormat.printBook.rawValue,
        quotations: [
            QuotationSeed(
                content: "Curiouser and curiouser!",
                location: "Ch. 2"
            ),
            QuotationSeed(
                content: "Who in the world am I? Ah, that's the great puzzle!",
                location: "Ch. 2"
            ),
            QuotationSeed(
                content: "We're all mad here. I'm mad. You're mad.",
                location: "Ch. 6"
            ),
            QuotationSeed(
                content: "Would you tell me, please, which way I ought to go from here?",
                location: "Ch. 6"
            ),
            QuotationSeed(
                content: "It's no use going back to yesterday, because I was a different person then.",
                location: "Ch. 10"
            ),
            QuotationSeed(
                content: "Begin at the beginning, and go on till you come to the end: then stop.",
                location: "Ch. 12"
            ),
            QuotationSeed(
                content: "Why, sometimes I've believed as many as six impossible things before breakfast.",
                location: "Through the Looking-Glass, Ch. 5"
            ),
            QuotationSeed(
                content: "No wise fish would go anywhere without a porpoise.",
                location: "Ch. 10"
            ),
            QuotationSeed(
                content: "I can't explain myself, I'm afraid, sir, because I'm not myself, you see.",
                location: "Ch. 5"
            ),
            QuotationSeed(
                content: "Everything's got a moral, if only you can find it.",
                location: "Ch. 9"
            ),
        ]
    )

    static let greatExpectations = SourceSeed(
        title: "Great Expectations",
        authorName: "Charles Dickens",
        publicationYear: 1861,
        format: SourceFormat.printBook.rawValue,
        quotations: [
            QuotationSeed(
                content: "I loved her against reason, against promise, against peace, against hope, against happiness, against all discouragement that could be.",
                location: "Ch. 29"
            ),
            QuotationSeed(
                content: "Take nothing on its looks; take everything on evidence. There's no better rule.",
                location: "Ch. 40"
            ),
            QuotationSeed(
                content: "We need never be ashamed of our tears.",
                location: "Ch. 19"
            ),
            QuotationSeed(
                content: "Suffering has been stronger than all other teaching, and has taught me to understand what your heart used to be.",
                location: "Ch. 59"
            ),
            QuotationSeed(
                content: "In a word, I was too cowardly to do what I knew to be right, as I had been too cowardly to avoid doing what I knew to be wrong.",
                location: "Ch. 27"
            ),
            QuotationSeed(
                content: "There was a long hard time when I kept far from me the remembrance of what I had thrown away when I was quite ignorant of its worth.",
                location: "Ch. 59"
            ),
            QuotationSeed(
                content: "I have been bent and broken, but—I hope—into a better shape.",
                location: "Ch. 59"
            ),
            QuotationSeed(
                content: "It was one of those March days when the sun shines hot and the wind blows cold: when it is summer in the light, and winter in the shade.",
                location: "Ch. 8"
            ),
            QuotationSeed(
                content: "Ask no questions, and you'll be told no lies.",
                location: "Ch. 2"
            ),
            QuotationSeed(
                content: "Life is made of ever so many partings welded together.",
                location: "Ch. 27"
            ),
        ]
    )

    static let theOdyssey = SourceSeed(
        title: "The Odyssey",
        authorName: "Homer",
        publicationYear: nil,
        format: SourceFormat.printBook.rawValue,
        quotations: [
            QuotationSeed(
                content: "Tell me, O Muse, of that ingenious hero who travelled far and wide after he had sacked the famous town of Troy.",
                location: "Book I"
            ),
            QuotationSeed(
                content: "Be strong, saith my heart; I am a soldier; I have seen worse sights than this.",
                location: "Book XX"
            ),
            QuotationSeed(
                content: "There is a time for many words, and there is also a time for sleep.",
                location: "Book XI"
            ),
            QuotationSeed(
                content: "A man who has been through bitter experiences and travelled far enjoys even his sufferings after a time.",
                location: "Book XV"
            ),
            QuotationSeed(
                content: "Of all creatures that breathe and move upon the earth, nothing is bred that is weaker than man.",
                location: "Book XVIII"
            ),
            QuotationSeed(
                content: "The gods themselves cannot recall their gifts.",
                location: "Book III"
            ),
            QuotationSeed(
                content: "Even his griefs are a joy long after to one that remembers all that he wrought and endured.",
                location: "Book XV"
            ),
            QuotationSeed(
                content: "So, I may know you when we meet in the hereafter, as once we knew each other on the earth.",
                location: "Book XI"
            ),
            QuotationSeed(
                content: "Few sons are like their fathers; many are worse; few, indeed, are better than their fathers.",
                location: "Book II"
            ),
            QuotationSeed(
                content: "By hook or by crook this peril too shall be something that we remember.",
                location: "Book XII"
            ),
        ]
    )

    static let dracula = SourceSeed(
        title: "Dracula",
        authorName: "Bram Stoker",
        publicationYear: 1897,
        format: SourceFormat.printBook.rawValue,
        quotations: [
            QuotationSeed(
                content: "Listen to them—the children of the night. What music they make!",
                location: "Ch. 2"
            ),
            QuotationSeed(
                content: "I am all in a sea of wonders. I doubt; I fear; I think strange things, which I dare not confess to my own soul.",
                location: "Ch. 2"
            ),
            QuotationSeed(
                content: "No man knows till he has suffered from the night how sweet and dear to his heart and eye the morning can be.",
                location: "Ch. 11"
            ),
            QuotationSeed(
                content: "We are in Transylvania; and Transylvania is not England. Our ways are not your ways, and there shall be to you many strange things.",
                location: "Ch. 2"
            ),
            QuotationSeed(
                content: "There are darknesses in life and there are lights, and you are one of the lights, the light of all lights.",
                location: "Ch. 14"
            ),
            QuotationSeed(
                content: "Denn die Todten reiten schnell. For the dead travel fast.",
                location: "Ch. 1"
            ),
            QuotationSeed(
                content: "I want you to believe… to believe in things that you cannot.",
                location: "Ch. 14"
            ),
            QuotationSeed(
                content: "Despair has its own calms.",
                location: "Ch. 10"
            ),
            QuotationSeed(
                content: "The blood is the life!",
                location: "Ch. 11"
            ),
            QuotationSeed(
                content: "We learn from failure, not from success!",
                location: "Ch. 10"
            ),
        ]
    )

    static let huckleberryFinn = SourceSeed(
        title: "Adventures of Huckleberry Finn",
        authorName: "Mark Twain",
        publicationYear: 1884,
        format: SourceFormat.printBook.rawValue,
        quotations: [
            QuotationSeed(
                content: "All right, then, I'll go to hell.",
                location: "Ch. 31"
            ),
            QuotationSeed(
                content: "Human beings can be awful cruel to one another.",
                location: "Ch. 33"
            ),
            QuotationSeed(
                content: "I do believe he cared just as much for his people as white folks does for their'n.",
                location: "Ch. 23"
            ),
            QuotationSeed(
                content: "What's the use you learning to do right when it's troublesome to do right and ain't no trouble to do wrong, and the wages is just the same?",
                location: "Ch. 16"
            ),
            QuotationSeed(
                content: "You can't pray a lie—I found that out.",
                location: "Ch. 31"
            ),
            QuotationSeed(
                content: "There ain't nothing that breaks up like a family row.",
                location: "Ch. 19"
            ),
            QuotationSeed(
                content: "I was a-trembling, because I'd got to decide, forever, betwixt two things, and I knowed it.",
                location: "Ch. 31"
            ),
            QuotationSeed(
                content: "Persons attempting to find a motive in this narrative will be prosecuted; persons attempting to find a moral in it will be banished; persons attempting to find a plot in it will be shot.",
                location: "Notice"
            ),
            QuotationSeed(
                content: "It's lovely to live on a raft. We had the sky up there, all speckled with stars, and we used to lay on our backs and look up at them, and discuss about whether they was made or only just happened.",
                location: "Ch. 12"
            ),
            QuotationSeed(
                content: "But I reckon I got to light out for the Territory ahead of the rest, because Aunt Sally she's going to adopt me and sivilize me, and I can't stand it. I been there before.",
                location: "Ch. 43"
            ),
        ]
    )
}
