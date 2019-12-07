import React from "react"
import { channel } from "./socket"
import FeedDisplay from "./feed_display"

const feeds = [
    "Hamilton's Room"
]

const App = () => {
    return (
        <>
            {feeds.map(feed => (
                <FeedDisplay
                    key={feed}
                    feed={feed}
                />
            ))}
        </>
    )
}

export default App