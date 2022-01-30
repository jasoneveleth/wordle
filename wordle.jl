function progress(count)
    if (count % 10 == 0)
        println(round(count / length(possible), digits=3))
    end
end

function checkmaker(index, letter)
    return word -> (word[index] == letter)
end

function checkmaker2(letter, frequency)
    return str -> (countletter(letter, str) >= frequency)
end

function passes(tests, word)
    for f in tests
        if f(word) == false
            return false
        end
    end
    return true
end

function countletter(letter, word)
    return count(i->(i==letter), word)
end

function avg(arr)
    sum(arr) / length(arr)
end

function num_greens(hidden, guess)
    green_count = 0
    for i in 1:length(hidden)
        if hidden[i] == guess[i]
            green_count += 1
        end
    end
    return green_count
end

function removefirst!(list, ele)
    index = 0
    for i in 1:length(list)
        if list[i] == ele
            index = i
            break
        end
    end
    deleteat!(list, index)
end

function num_yellows(hidden, guess)
    num = 0
    hls = []
    gls = []
    for i in 1:length(hidden)
        if hidden[i] != guess[i]
            push!(hls, hidden[i])
            push!(gls, guess[i])
        end
    end
    for j in 1:length(gls)
        if gls[j] in hls
            removefirst!(hls, gls[j])
            num += 1
        end
    end
    num
end

"""
Like find most info, but exclude words involving the letters of the fst_word
"""
function find_info_snd(guess_list, hidden_list, fst_word)
    scores = zeros(Int32, length(guess_list))
    Threads.@threads for i in 1:length(guess_list)
        guess = guess_list[i]
        score = 0
        for hidden in hidden_list
            score += 2 * num_greens(hidden, guess)
            score += num_yellows(hidden, guess)
        end
        for i in 1:5
            if guess[i] in fst_word
                score -= 10000
            end
        end
        scores[i] = score
    end
    return scores
end

"""
The words that are ranked highest are ones that give the most other possible
words.
"""
function find_most_possible_left(words_list)
    scores = zeros(Int32, length(words_list))
    Threads.@threads for count in 1:length(words_list)
        p = words_list[count]
        num_matches = 0

        for correct in words_list
            # make all check functions
            checks = []
            for i in 1:5
                if correct[i] == p[i]
                    push!(checks, checkmaker(i, correct[i]))
                end
                if p[i] in correct
                    mini = min(countletter(p[i], p), countletter(p[i], correct))
                    push!(checks, checkmaker2(p[i], mini))
                end
            end

            # check how many words pass
            for d in words_list
                if passes(checks, d)
                    num_matches += 1
                end
            end
        end
        scores[count] = num_matches
    end
    return scores
end

"""
The words that are ranked highest are ones that have the most green and yellow
letters.
"""
function find_most_information(guess_list, hidden_list)
    scores = zeros(Int32, length(guess_list))
    Threads.@threads for i in 1:length(guess_list)
        guess = guess_list[i]
        score = 0
        for hidden in hidden_list
            score += 2 * num_greens(hidden, guess)
            score += num_yellows(hidden, guess)
        end
        scores[i] = score
    end
    return scores
end

function file2arr(filename)
    easy_mut_lines = []
    open(filename) do f
        while !eof(f)
            push!(easy_mut_lines, readline(f))
        end
    end
    return easy_mut_lines
end

function main()
    easy_dict_list = file2arr("easy_dict.txt")
    hard_dict_list = file2arr("hard_dict.txt")
    both = [easy_dict_list; hard_dict_list]

    guess = both
    hidden = easy_dict_list
    # word_scores = find_most_possible_left(hidden)
    # word_scores = find_most_information(guess, hidden)
    word_scores = find_info_snd(guess, hidden, "soare")

    # the ith index of this array is ith best word
    indices = sortperm(word_scores, rev=true)

    # print results
    for i in 1:10
        word = guess[indices[i]]
        score = word_scores[indices[i]]
        println(i, ". ", word, " with ", score)
    end
    println("...")
    for i in length(guess)-10:length(guess)
        word = guess[indices[i]]
        score = word_scores[indices[i]]
        println(i, ". ", word, " with ", score)
    end

    # this is how to call besttwo()
    # println(besttwo(easy_dict_list, both))
end

main()
