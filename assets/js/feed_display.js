import React, { useEffect, useState, useReducer } from "react"
import { connectChannel } from "./socket"
import { VictoryChart, VictoryTheme, VictoryLine, VictoryScatter, VictoryAxis } from "victory"
import { format } from "date-fns"

const reducer = (state, action) => {
    switch (action.type) {
        case "set_initial": return Object
            .entries(action.payload)
            .map(([name, data]) => ({
                [name]: data.map(transformMetric)
            }))
            .reduce((acc, curr) => ({
                ...acc,
                ...curr
            }))

        case "add_metric":
            const { name } = action.payload
            const existingArray = state[name] || []
            const newArray = existingArray.length >= 5 ? [
                ...existingArray.slice(1),
                transformMetric(action.payload)
            ] : [
                    ...existingArray,
                    transformMetric(action.payload)
                ]

            return {
                ...state,
                [name]: newArray
            }
        default: throw new Error()
    }
}

const transformMetric = (metric) => {
    const { name, created_at } = metric

    return {
        x: formatDate(created_at),
        y: metric[name],
    }
}

const formatDate = createdAt => format(new Date(createdAt), "mm:ss")

const FeedDisplay = ({ feed }) => {
    const [channel, setChannel] = useState(null)
    const [isConnected, setIsConnected] = useState(false)
    const [didError, setDidError] = useState(false)
    const [groupedMetrics, dispatch] = useReducer(reducer, {})

    useEffect(() => {
        const connected = connectChannel(feed)
        setChannel(connected)
        connected.join()
            .receive("ok", resp => {
                dispatch({ type: "set_initial", payload: resp })
                setIsConnected(true)
            }).receive("error", () => {
                setIsConnected(false)
                setDidError(true)
            })

        connected.onClose(() => {
            setIsConnected(false)
        })

        connected.onError(() => {
            setDidError(true)
        })

        return () => {
            connected.leave()
        }
    }, [feed])

    useEffect(() => {
        if (!channel) return
        channel.on("metric_added", newInfo => {
            dispatch({ type: "add_metric", payload: { ...newInfo } })
        })
    }, [channel])

    return (
        <div style={{ height: "100%", display: "flex", flexWrap: "wrap", width: "100%", alignItems: "center", justifyContent: "center" }}>
            {Object.entries(groupedMetrics).map(([source, data]) => (
                <MetricHistoryChart
                    source={source}
                    key={source}
                    data={data}
                />
            ))}
        </div>
    )
}

const MetricHistoryChart = ({ data, source }) => (
    <div style={{ minWidth: 600 }}>
        <header>
            {source}
        </header>
        <main>
            <VictoryChart
                animate={{
                    duration: 1500,
                    onExit: {
                        duration: 500,
                        before: () => ({
                            _y: 0,
                        })
                    }
                }}
                theme={VictoryTheme.grayscale}>
                <VictoryAxis
                    domain={domains[source]}
                    dependentAxis
                    orientation="left"
                    standalone={false}
                    style={{ grid: { stroke: "rgba(60,60,60,0.2)" } }}
                />
                <VictoryAxis
                    standalone={false}
                    style={
                        {
                            grid: {
                                stroke: "rgba(60,60,60,1)",
                                strokeWidth: 1
                            },
                            axis: {
                                stroke: "rgba(225, 255, 255, 1)",
                                strokeWidth: 0
                            },
                            ticks: {
                                strokeWidth: 0
                            }
                        }}
                />
                <VictoryLine
                    width={600}
                    style={{
                        data: { stroke: "#c43a31" },

                    }}
                    data={data}
                />
                <VictoryScatter
                    width={600}
                    data={data}
                    samples={25}
                    size={5}
                    style={{
                        data: { fill: "#c43a31" },
                    }}
                />
            </VictoryChart>
        </main>
    </div>
)

const domains = {
    "temp": [65, 75],
    "humidity": [35, 45]
}

export default FeedDisplay