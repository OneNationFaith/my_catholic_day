import '../../models/prayer.dart';

const List<Prayer> dailyPrayers = [
  Prayer(
    id: "morning-offering",
    title: "Morning Offering",
    category: "Daily Prayer",
    scripture:
        "This is the day the Lord has made; let us rejoice and be glad.",
    scriptureReference: "Psalm 118:24",
    reflection:
        "The Morning Offering dedicates your entire day—its joys, sufferings, work, and prayer—to God.",
    prayer:
        "O Jesus, through the Immaculate Heart of Mary, I offer You my prayers, works, joys, and sufferings of this day for all the intentions of Your Sacred Heart, in union with the Holy Sacrifice of the Mass throughout the world. Amen.",
    action: "Begin your day by offering every task to God.",
    tags: ["morning", "offering"],
  ),
  Prayer(
    id: "before-meals",
    title: "Grace Before Meals",
    category: "Daily Prayer",
    scripture:
        "Whether you eat or drink, do everything for the glory of God.",
    scriptureReference: "1 Corinthians 10:31",
    reflection:
        "Every meal is a reminder that God lovingly provides for His children.",
    prayer:
        "Bless us, O Lord, and these Thy gifts, which we are about to receive from Thy bounty, through Christ our Lord. Amen.",
    action: "Thank God for those who prepared your meal.",
    tags: ["food", "meal"],
  ),
  Prayer(
    id: "after-meals",
    title: "Grace After Meals",
    category: "Daily Prayer",
    scripture: "Give thanks to the Lord, for He is good.",
    scriptureReference: "Psalm 107:1",
    reflection:
        "Gratitude keeps our hearts focused on God's goodness.",
    prayer:
        "We give You thanks, Almighty God, for all Your benefits, who live and reign forever and ever. Amen.",
    action: "Spend a moment thanking God for today's blessings.",
    tags: ["gratitude"],
  ),
  Prayer(
    id: "before-work",
    title: "Prayer Before Work",
    category: "Daily Prayer",
    scripture:
        "Whatever you do, work at it with all your heart, as for the Lord.",
    scriptureReference: "Colossians 3:23",
    reflection:
        "Our daily work becomes holy when it is offered to God with love.",
    prayer:
        "Lord, bless the work I do today. Give me wisdom, patience, honesty, and charity toward everyone I meet. May all I accomplish give glory to You. Amen.",
    action: "Offer your first task today to God.",
    tags: ["work"],
  ),
  Prayer(
    id: "before-travel",
    title: "Prayer Before Traveling",
    category: "Daily Prayer",
    scripture: "The Lord will guard your coming and your going.",
    scriptureReference: "Psalm 121:8",
    reflection:
        "Ask God's protection for every journey, whether long or short.",
    prayer:
        "Heavenly Father, protect me as I travel today. Keep me safe from harm and bring me peacefully to my destination. Amen.",
    action: "Pray for everyone traveling today.",
    tags: ["travel"],
  ),
  Prayer(
    id: "before-study",
    title: "Prayer Before Study",
    category: "Daily Prayer",
    scripture: "If any of you lacks wisdom, ask God.",
    scriptureReference: "James 1:5",
    reflection:
        "Learning is one way we grow in the gifts God has given us.",
    prayer:
        "Holy Spirit, enlighten my mind and strengthen my memory. Help me understand what I study and use my knowledge for Your glory. Amen.",
    action: "Begin your work with one minute of silence.",
    tags: ["study"],
  ),
  Prayer(
    id: "family-prayer",
    title: "Family Prayer",
    category: "Daily Prayer",
    scripture: "As for me and my house, we will serve the Lord.",
    scriptureReference: "Joshua 24:15",
    reflection:
        "Families grow stronger when they pray together.",
    prayer:
        "Lord, bless our family. Help us love one another, forgive quickly, and always place You at the center of our home. Amen.",
    action: "Pray together as a family today.",
    tags: ["family"],
  ),
  Prayer(
    id: "night-prayer",
    title: "Night Prayer",
    category: "Daily Prayer",
    scripture: "In peace I will lie down and sleep.",
    scriptureReference: "Psalm 4:8",
    reflection:
        "End the day by placing your worries into God's hands.",
    prayer:
        "Lord, thank You for today. Forgive my failures, strengthen my faith, and grant me peaceful rest through the night. Amen.",
    action: "Reflect on one blessing from today.",
    tags: ["night"],
  ),
  Prayer(
    id: "act-of-contrition",
    title: "Act of Contrition",
    category: "Daily Prayer",
    scripture: "Create in me a clean heart, O God.",
    scriptureReference: "Psalm 51:10",
    reflection:
        "God's mercy is always greater than our sins.",
    prayer:
        "O my God, I am heartily sorry for having offended You, and I detest all my sins because of Your just punishments, but most of all because they offend You, my God, who are all good and deserving of all my love. I firmly resolve, with the help of Your grace, to sin no more and to avoid the near occasions of sin. Amen.",
    action: "Make a brief examination of conscience.",
    tags: ["confession", "forgiveness"],
  ),
  Prayer(
    id: "spiritual-communion",
    title: "Spiritual Communion",
    category: "Daily Prayer",
    scripture:
        "Whoever eats my flesh and drinks my blood remains in me.",
    scriptureReference: "John 6:56",
    reflection:
        "When you cannot receive the Eucharist sacramentally, unite yourself spiritually to Christ.",
    prayer:
        "My Jesus, I believe that You are present in the Most Holy Sacrament. I love You above all things, and I desire to receive You into my soul. Since I cannot at this moment receive You sacramentally, come at least spiritually into my heart. I embrace You as if You were already there and unite myself wholly to You. Never permit me to be separated from You. Amen.",
    action: "Spend a quiet minute with Jesus.",
    tags: ["communion", "eucharist"],
  ),
  Prayer(
    id: "saint-michael",
    title: "Prayer to Saint Michael",
    category: "Daily Prayer",
    scripture: "Put on the armor of God.",
    scriptureReference: "Ephesians 6:11",
    reflection:
        "Saint Michael reminds us that our strength and protection come from God.",
    prayer:
        "Saint Michael the Archangel, defend us in battle. Be our protection against the wickedness and snares of the devil. May God rebuke him, we humbly pray; and do thou, O Prince of the heavenly host, by the power of God, cast into hell Satan and all the evil spirits who prowl about the world seeking the ruin of souls. Amen.",
    action: "Pray for protection over your family.",
    tags: ["saint michael", "protection"],
  ),
  Prayer(
    id: "angelus",
    title: "The Angelus",
    category: "Daily Prayer",
    scripture: "The Word became flesh and dwelt among us.",
    scriptureReference: "John 1:14",
    reflection:
        "The Angelus recalls the mystery of the Incarnation and Mary's faithful response to God.",
    prayer: """
The Angel of the Lord declared unto Mary.
And she conceived of the Holy Spirit.

Hail Mary, full of grace, the Lord is with thee; blessed art thou among women, and blessed is the fruit of thy womb, Jesus.

Holy Mary, Mother of God, pray for us sinners, now and at the hour of our death. Amen.

Behold the handmaid of the Lord.
Be it done unto me according to thy word.

Hail Mary, full of grace, the Lord is with thee; blessed art thou among women, and blessed is the fruit of thy womb, Jesus.

Holy Mary, Mother of God, pray for us sinners, now and at the hour of our death. Amen.

And the Word was made flesh.
And dwelt among us.

Hail Mary, full of grace, the Lord is with thee; blessed art thou among women, and blessed is the fruit of thy womb, Jesus.

Holy Mary, Mother of God, pray for us sinners, now and at the hour of our death. Amen.

Pray for us, O holy Mother of God,
that we may be made worthy of the promises of Christ.

Let us pray:

Pour forth, we beseech Thee, O Lord, Thy grace into our hearts, that we, to whom the Incarnation of Christ Thy Son was made known by the message of an angel, may by His Passion and Cross be brought to the glory of His Resurrection. Through the same Christ our Lord. Amen.
""",
    action:
        "Pause in the morning, at noon, or in the evening to remember the Incarnation.",
    tags: ["angelus", "mary", "incarnation"],
  ),
];