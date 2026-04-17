/ Schema for the official kdb+tick tickerplant

trade:([] time:`timestamp$(); sym:`symbol$(); price:`float$(); size:`long$())
quote:([] time:`timestamp$(); sym:`symbol$(); bid:`float$(); ask:`float$(); bsize:`long$(); asize:`long$())

t:(`trade`quote)!(trade;quote)
